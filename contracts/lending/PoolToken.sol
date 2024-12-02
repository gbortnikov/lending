// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PausableUpgradeable, Initializable} from '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';
import {IERC20Metadata} from '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import {SafeCast} from '@openzeppelin/contracts/utils/math/SafeCast.sol';

import {AggregatorV3Interface} from './external/AggregatorV3Interface.sol';
import {IPoolToken} from './interfaces/IPoolToken.sol';

contract PoolToken is IPoolToken, Initializable, PausableUpgradeable {
    using SafeCast for uint256;
    using SafeCast for int256;

    uint256 public constant PRECISION = 1e18;
    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// The address of the adapter contract that interacts with the pool.
    address public adapter;
    /// The address of the configurator contract that sets the configuration of the pool.
    address public configurator;
    /// The address of the data feed used to get the price of the token.
    AggregatorV3Interface public dataFeed;

    AggregatorV3Interface public dataFeedTokenUsd;
    uint256 internal _dataFeedDecimalsTokenUsd;

    /// The address of the token0 used in the pool.
    address internal _token0;
    /// The address of the token1 used in the pool.
    address internal _token1;
    /// the health factor that should be after liquidation
    uint128 internal _healthPurpose;
    /// The number of decimals of the data feed.
    uint256 internal _dataFeedDecimals;
    /// The number of decimals of token0.
    uint256 internal _decimalsToken0;
    /// The number of decimals of token1.
    uint256 internal _decimalsToken1;
    /// The acceptable time interval to update the borrow rate.
    uint256 internal _acceptableTimeInterval;
    /// The percentage of the reward for liquidation given to the liquidator.
    uint256 internal _rewardLiquidatorPercent;
    /// The percentage of the reward for liquidation given to the platform.
    uint256 internal _rewardPlatformPercent;
    /// The borrow rate per second.
    uint256 internal _borrowRatePerSec;
    /// The timestamp of the last update of the borrow rate.
    uint256 internal _lastUpdateRate;
    /// stores the last value of K that was at the time of the change the loan fee
    uint256 internal _k;
    /// The fixed reward for extra liquidation.
    uint256 internal _extraReward;
    /// The minimum health factor for opening a position
    int256 internal _minHealthPercent;
    /// The health percentage threshold for liquidation.
    int256 internal _liquidateHealthPercent;

    uint256 internal _minLoan;

    /// The mapping that stores the positions of the lending pool. ID => Position
    mapping(uint256 => Position) internal _positionById;

    modifier onlyAdapter() {
        if (msg.sender != adapter) {
            revert OnlyAdapter();
        }
        _;
    }

    modifier onlyConfigurator() {
        if (msg.sender != configurator) {
            revert OnlyConfigurator();
        }
        _;
    }

    /// Initialize the contract with the initial values of the variables.
    /// This function is called during the contract deployment.
    /// @param token0: The address of the first token in the pool.
    /// @param token1: The address of the second token in the pool.
    /// @param chainlinkAggregator: The address of the Chainlink aggregator contract.
    /// @param addrAdapter: The address of the adapter contract.
    /// @param addrConfigurator: The address of the configurator contract.
    function initialize(
        address token0,
        address token1,
        address chainlinkAggregator,
        address addrAdapter,
        address addrConfigurator,
        address chainlinkAggregatorTokenUsd
    ) external initializer {
        // Check if any of the provided addresses is zero.
        if (
            token1 == address(0) ||
            chainlinkAggregator == address(0) ||
            addrAdapter == address(0) ||
            addrConfigurator == address(0)
        ) {
            // Revert the transaction if any of the provided addresses is zero.
            revert ZeroAddress();
        }

        // Set the values of the variables.
        _token0 = token0;
        _token1 = token1;
        adapter = addrAdapter;
        configurator = addrConfigurator;

        // Set the address of the Chainlink aggregator contract.
        dataFeed = AggregatorV3Interface(chainlinkAggregator);
        dataFeedTokenUsd = AggregatorV3Interface(chainlinkAggregatorTokenUsd);
        // Get the number of decimals of the price data from the Chainlink aggregator contract.
        _dataFeedDecimals = dataFeed.decimals();
        _dataFeedDecimalsTokenUsd = dataFeedTokenUsd.decimals();

        // Get the number of decimals of the first token.
        _decimalsToken0 = IERC20Metadata(token0).decimals();
        _acceptableTimeInterval = 2 days;

        // If the second token is not the native token, get its number of decimals.
        // Otherwise, set it to 18.
        if (token1 != NATIVE) {
            _decimalsToken1 = IERC20Metadata(token1).decimals();
        } else {
            _decimalsToken1 = 18;
        }

        __Pausable_init();
    }

    /// Pauses the contract. Only the configurator can pause it.
    function pause() external override onlyConfigurator {
        _pause();
    }

    /// Unpauses the contract. Only the configurator can unpause it.
    function unpause() external override onlyConfigurator {
        _unpause();
    }

    /// @dev Sets the configuration of the contract.
    /// It allows the configurator to update the address of the Chainlink aggregator contract and the acceptable time interval.
    /// @param newDataFeed The new address of the Chainlink aggregator contract.
    /// @param newAcceptableTimeInterval The new acceptable time interval.
    function setConfig(
        address newDataFeed,
        uint256 newAcceptableTimeInterval,
        address newDataFeedTokenUsd
    ) external override onlyConfigurator {
        dataFeed = AggregatorV3Interface(newDataFeed);
        _acceptableTimeInterval = newAcceptableTimeInterval;
        dataFeedTokenUsd = AggregatorV3Interface(newDataFeedTokenUsd);
        emit ConfigUpdated({dataFeed: newDataFeed, acceptableTimeInterval: newAcceptableTimeInterval});
    }

    /// @dev Sets the extra reward. Only the configurator can set it.
    /// @param extraReward fixed reward for extra liquidation.
    function setExtraReward(uint256 extraReward) external override onlyConfigurator {
        _extraReward = extraReward;
    }

    /// @dev Set the borrow rate of the contract. Only the configurator can set it.
    /// The precision of the borrow rate is 18.
    /// Example 5% = 5e18
    /// @notice The borrow rate is the annual interest rate that borrowers pay to lenders.
    /// The function converts the borrow rate per year to a borrow rate per second.
    /// The borrow rate is stored in `_borrowRatePerSec` and `_lastUpdateRate` is updated to the current block timestamp.
    function setBorrowRate(uint256 borrowRatePerYear) external override onlyConfigurator {
        // Calculate the current value of `_k`
        _k = _calcK();
        // Convert the borrow rate per year to a borrow rate per second
        _borrowRatePerSec = borrowRatePerYear / 365 days;
        _lastUpdateRate = block.timestamp;
        emit BorrowRateUpdated({borrowRatePerSec: _borrowRatePerSec});
    }

    /// @dev Sets the health configuration of the contract.
    /// This function allows the configurator to update the minimum health percentage, liquidation health percentage, and health purpose.
    /// Sum of the `newHealthPurpose`, `rewardLiquidatorPercent`, `rewardPlatformPercent` percentages must be less than or equal 10000.
    /// The precision of the all percentages is 2.
    /// Example 5% = 5e2
    /// @param newMinHealthPercent The new minimum health percentage.
    /// @param newLiquidateHealthPercent The new liquidation health percentage.
    /// @param newHealthPurpose The new health purpose.
    /// The function updates the `_minHealthPercent`, `_liquidateHealthPercent`, and `_healthPurpose` variables with the new values.
    /// It then emits a `HealthConfigUpdated` event with the new health configuration.
    function setHealthRewardConfig(
        uint256 newMinHealthPercent,
        uint256 newLiquidateHealthPercent,
        uint128 newHealthPurpose,
        uint256 newRewardLiquidatorPercent,
        uint256 newRewardPlatformPercent
    ) external override onlyConfigurator {
        // Check if the sum of the three percentages is greater than 10000 (representing 100%)
        if (newHealthPurpose + newRewardLiquidatorPercent + newRewardPlatformPercent >= 100_00) {
            revert InvalidHealthPurpose(newHealthPurpose + _rewardLiquidatorPercent + _rewardPlatformPercent);
        }

        _minHealthPercent = int256(newMinHealthPercent);
        _liquidateHealthPercent = int256(newLiquidateHealthPercent);
        _healthPurpose = newHealthPurpose;
        _rewardLiquidatorPercent = newRewardLiquidatorPercent;
        _rewardPlatformPercent = newRewardPlatformPercent;

        emit HealthRewardConfigUpdated({
            minHealthPercent: newMinHealthPercent,
            liquidateHealthPercent: newLiquidateHealthPercent,
            healthPurpose: newHealthPurpose,
            rewardLiquidatorPercent: newRewardLiquidatorPercent,
            rewardPlatformPercent: newRewardPlatformPercent
        });
    }

    function setMinLoan(uint256 newMinLoan) external override onlyConfigurator {
        _minLoan = newMinLoan;
    }

    /// Creates a new position with the given `loan` and `collateral` amounts.
    /// @param loan The amount of the loan to be borrowed.
    /// @param collateral The amount of collateral to be put up as collateral.
    /// @param posId The ID of the new position.
    function borrow(uint128 loan, uint128 collateral, uint256 posId) external override onlyAdapter whenNotPaused {
        if (loan < _minLoan) {
            revert LoanLessThanMinLoan(loan, _minLoan);
        }
        uint256 k = _calcK();
        uint256 priceUsdToken = getPrice(dataFeedTokenUsd);
        uint256 loanUsd = _convertToBaseCurrency(loan, priceUsdToken, 18, _dataFeedDecimalsTokenUsd);
        uint256 price = getPrice(dataFeed);
        _validatePosition(loanUsd, collateral, price);
        _positionById[posId] = Position(collateral, loan, k);
    }

    /// Adds more loan and collateral to an existing position.
    /// This function allows a user to add more loan and collateral to an existing position.
    /// @param posId The ID of the position to add more loan and collateral to.
    /// @param collateral The amount of collateral to add to the position.
    /// @param loan The amount of loan to add to the position.
    function borrowMore(
        uint256 posId,
        uint128 collateral,
        uint128 loan
    ) external override onlyAdapter whenNotPaused returns (uint256 commissionQuote) {
        Position storage position = _positionById[posId];

        if (position.loan == 0) {
            revert PositionEmpty(posId);
        }
        uint256 priceUsdToken = getPrice(dataFeedTokenUsd);
        uint256 loanUsd = _convertToBaseCurrency(position.loan, priceUsdToken, 18, _dataFeedDecimalsTokenUsd);

        uint256 price = getPrice(dataFeed);
        uint256 currentK = _calcK();

        (, commissionQuote) = _calculateLoanFees(loanUsd, position.k, currentK, price);

        position.collateral = position.collateral + collateral - uint128(commissionQuote);
        position.loan += loan;
        position.k = currentK;

        loanUsd = _convertToBaseCurrency(loan, priceUsdToken, 18, _dataFeedDecimalsTokenUsd);
        _validatePosition(loanUsd, position.collateral, price);
    }

    /// Repays a loan from a position.
    /// This function allows a user to repay a loan from a position. If the `loanRepayment` is equal to the total loan amount of the position, the function deletes the position and returns the entire collateral as a refund. Otherwise, it decreases the loan amount by `loanRepayment` and increases the collateral by `refundCollateral`.
    /// @param loanRepayment The amount of loan to be repaid.
    /// @param posId The ID of the position to repay the loan from.
    /// @param refundCollateral The amount of collateral to be refunded.
    /// @return refundColl The amount of collateral refunded.
    /// @return isClosePosition A boolean indicating whether the position was closed.
    /// @return commissionQuote The amount of commission charged.
    function repay(
        uint128 loanRepayment,
        uint256 posId,
        uint128 refundCollateral
    )
        external
        override
        onlyAdapter
        whenNotPaused
        returns (uint256 refundColl, bool isClosePosition, uint256 commissionQuote)
    {
        Position storage position = _positionById[posId];
        if (loanRepayment > position.loan || refundCollateral > position.collateral) {
            revert InvalidRepayment(position.loan, position.collateral);
        }

        uint256 priceUsdToken = getPrice(dataFeedTokenUsd);
        uint256 loanUsd = _convertToBaseCurrency(position.loan, priceUsdToken, 18, _dataFeedDecimalsTokenUsd);

        uint256 price = getPrice(dataFeed);
        uint256 currentK = _calcK();
        (, commissionQuote) = _calculateLoanFees(loanUsd, position.k, currentK, price);

        if (position.loan == loanRepayment) {
            refundCollateral = position.collateral;
            delete _positionById[posId];
            return (refundCollateral, true, commissionQuote);
        }
        position.loan -= loanRepayment;
        position.collateral = position.collateral - refundCollateral - uint128(commissionQuote);
        position.k = currentK;

        loanUsd = _convertToBaseCurrency(position.loan, priceUsdToken, 18, _dataFeedDecimalsTokenUsd);
        _validatePosition(loanUsd, position.collateral, price);

        return (refundCollateral, false, commissionQuote);
    }

    /// Liquidates the position with the given ID.
    /// The function calculates the health factor of the position and checks if it is in the liquidation zone.
    /// If it is, the function calculates the liquidation amount based on the health factor and the liquidation rate.
    /// It then updates the position's loan, collateral, and K-value.
    /// @param posId The ID of the position to liquidate.
    /// @return liqLoan The amount of loan liquidated.
    /// @return liqColl The amount of collateral liquidated.
    /// @return rewPlatform The amount of platform reward.
    /// @return rewLiquidator The amount of liquidator reward.
    /// @return commissionQuote The amount of commission charged.
    function liquidate(
        uint256 posId
    )
        external
        override
        onlyAdapter
        whenNotPaused
        returns (uint256 liqLoan, uint128 liqColl, uint256 rewPlatform, uint256 rewLiquidator, uint256 commissionQuote)
    {
        // Get the position to liquidate and calculate the price and current K-value
        Position storage position = _positionById[posId];

        uint256 priceUsdToken = getPrice(dataFeedTokenUsd);
        uint256 loanUsd = _convertToBaseCurrency(position.loan, priceUsdToken, 18, _dataFeedDecimalsTokenUsd);

        uint256 price = getPrice(dataFeed);
        uint256 currentK = _calcK();
        uint256 commissionBase;

        // Calculate the commission based on the loan and current K-value
        (commissionBase, commissionQuote) = _calculateLoanFees(loanUsd, position.k, currentK, price);
        uint256 collateralToBaseCurrency = _convertToBaseCurrency(
            position.collateral,
            price,
            _decimalsToken1,
            _dataFeedDecimals
        );

        // Calculate the health factor and check if it is in the liquidation zone
        int256 healthFactor = _calcHealth(loanUsd, collateralToBaseCurrency - commissionBase);
        if (healthFactor >= _liquidateHealthPercent) {
            revert PositionNotInLiquidationZone(healthFactor, _liquidateHealthPercent);
        }
        if (healthFactor < 0) {
            revert PositionUnderwater();
        }

        // Calculate the liquidation amount based on the health factor and the liquidation rate
        (liqLoan, rewPlatform, rewLiquidator) = _calcLiquidation(loanUsd, collateralToBaseCurrency - commissionBase);

        position.loan -= uint128(_convertToQuoteCurrency(liqLoan, priceUsdToken, _dataFeedDecimalsTokenUsd));

        liqColl = uint128(_convertToQuoteCurrency(liqLoan, price, _dataFeedDecimals));
        position.collateral -= (liqColl + uint128(commissionQuote));
        position.k = currentK;

        return (
            uint128(_convertToQuoteCurrency(liqLoan, priceUsdToken, _dataFeedDecimalsTokenUsd)),
            liqColl,
            _convertToQuoteCurrency(rewPlatform, price, _dataFeedDecimals),
            _convertToQuoteCurrency(rewLiquidator, price, _dataFeedDecimals),
            commissionQuote
        );
    }

    /// Extra liquidation of the position. This works if the operability of the position is below zero
    /// @param posId The ID of the position to be liquidated.
    /// @return liqLoan The total amount of loan to be liquidated.
    /// @return liqColl The total amount of collateral to be liquidated.
    /// @return extraReward The additional reward given to the liquidator for extra liquidation.
    /// @return lossQuote The loss incurred by the platform.
    function extraLiquidate(
        uint256 posId
    ) external override onlyAdapter returns (uint256 liqLoan, uint128 liqColl, uint256 extraReward, int256 lossQuote) {
        Position storage position = _positionById[posId];
        uint256 price = getPrice(dataFeed);
        uint256 currentK = _calcK();

        (uint256 commissionBase, ) = _calculateLoanFees(position.loan, position.k, currentK, price);
        uint256 collateralToBaseCurrency = _convertToBaseCurrency(
            position.collateral,
            price,
            _decimalsToken1,
            _dataFeedDecimals
        );

        int256 healthFactor = _calcHealth(position.loan, collateralToBaseCurrency - commissionBase);
        if (healthFactor > 0) {
            revert PositionNotUnderwater(healthFactor);
        }
        liqLoan = position.loan;
        liqColl = position.collateral;
        extraReward = _rewardForExtraLiquidation();
        int256 lossBase = int256(collateralToBaseCurrency) - int128(position.loan);
        lossQuote = lossBase > 0
            ? int256(_convertToQuoteCurrency(uint256(lossBase), price, _dataFeedDecimals))
            : -int256(_convertToQuoteCurrency(uint256(-lossBase), price, _dataFeedDecimals));
        delete _positionById[posId];

        return (liqLoan, liqColl, extraReward, lossQuote);
    }

    /// @notice Returns the current K value of the pool.
    /// @return The current K value.
    function getCurrentK() external view override returns (uint256) {
        return _calcK();
    }

    /// @notice Returns the health configuration of the pool.
    /// @return minHealthPercent The minimum health percentage.
    /// @return liquidateHealthPercent The liquidation health percentage.
    /// @return healthPurpose The health purpose.
    function getHealthConfig()
        external
        view
        override
        returns (int256 minHealthPercent, int256 liquidateHealthPercent, uint128 healthPurpose)
    {
        return (_minHealthPercent, _liquidateHealthPercent, _healthPurpose);
    }

    /// @notice Returns the reward configuration of the pool.
    /// @return rewardLiquidatorPercent The percentage of rewards for liquidators.
    /// @return rewardPlatformPercent The percentage of rewards for the platform.
    function getRewardConfig()
        external
        view
        override
        returns (uint256 rewardLiquidatorPercent, uint256 rewardPlatformPercent)
    {
        return (_rewardLiquidatorPercent, _rewardPlatformPercent);
    }

    /// @notice Returns the borrow rate information of the pool.
    /// @return borrowRatePerSec The borrow rate per second.
    /// @return lastUpdateRate The timestamp of the last borrow rate update.
    function getBorrowRateInfo() external view override returns (uint256 borrowRatePerSec, uint256 lastUpdateRate) {
        return (_borrowRatePerSec, _lastUpdateRate);
    }

    /// @notice Returns the acceptable time interval of the chainlink
    function getAcceptableTimeInterval() external view override returns (uint256) {
        return _acceptableTimeInterval;
    }

    /// @notice Returns the information of a position.
    /// This function calculates the health factor of the position by calling `_calcHealth`.
    /// It also calculates the base currency and quote currency commissions by calling `_calculateLoanFees`.
    /// The function then returns the position details, health factor, and commissions.
    /// @param posId The ID of the position.
    /// @return position The position details.
    /// @return healthFactor The health factor of the position.
    /// @return commissionBase The base currency commission.
    /// @return commissionQuote The quote currency commission.
    function getInfoPosition(
        uint256 posId
    )
        external
        view
        override
        returns (Position memory position, int256 healthFactor, uint256 commissionBase, uint256 commissionQuote)
    {
        position = _positionById[posId];
        uint256 priceUsdToken = getPrice(dataFeedTokenUsd);
        uint256 loanUsd = _convertToBaseCurrency(position.loan, priceUsdToken, 18, _dataFeedDecimalsTokenUsd);

        uint256 price = getPrice(dataFeed);
        uint256 currentK = _calcK();

        (commissionBase, commissionQuote) = _calculateLoanFees(loanUsd, position.k, currentK, price);
        uint256 collateralToBaseCurrency = _convertToBaseCurrency(
            position.collateral - commissionQuote,
            price,
            _decimalsToken1,
            _dataFeedDecimals
        );
        healthFactor = _calcHealth(loanUsd, collateralToBaseCurrency);

        return (position, healthFactor, commissionBase, commissionQuote);
    }

    /// @notice Returns the token addresses of the pool.
    /// @return token0 The address of the first token.
    /// @return token1 The address of the second token.
    function getTokens() external view override returns (address token0, address token1) {
        return (_token0, _token1);
    }

    /// @notice Calculates the health factor of a position.
    /// @param posId The ID of the position.
    /// @return healthFactor The health factor of the position.
    function getPositionHealth(uint256 posId) public view returns (int256 healthFactor) {
        Position memory position = _positionById[posId];

        uint256 priceUsdToken = getPrice(dataFeedTokenUsd);
        uint256 loanUsd = _convertToBaseCurrency(position.loan, priceUsdToken, 18, _dataFeedDecimalsTokenUsd);

        uint256 currentK = _calcK();
        uint256 price = getPrice(dataFeed);
        (uint256 commissionBase, ) = _calculateLoanFees(loanUsd, position.k, currentK, price);
        uint256 collateralToBaseCurrency = _convertToBaseCurrency(
            position.collateral,
            price,
            _decimalsToken1,
            _dataFeedDecimals
        );

        return _calcHealth(loanUsd, collateralToBaseCurrency - commissionBase);
    }

    /// @notice This function receives data from the chainlink and returns the current price of the  pair token0/token1
    /// @dev It also checks if the price is older than the acceptable time interval and throws an error if it is.
    function getPrice(AggregatorV3Interface feed) public view returns (uint256) {
        (, int256 price, , uint256 updatedAt, ) = feed.latestRoundData();
        if (updatedAt + _acceptableTimeInterval < block.timestamp) {
            revert OracleOldPrice(updatedAt, block.timestamp);
        }
        return uint256(price);
    }

    /**
     * @dev Validates the position by checking its health factor. If the health factor is below the minimum
     * health percent, it reverts the transaction.
     *
     * @param loan The loan amount of the position.
     * @param collateral The collateral amount of the position.
     * @param price The current price of the underlying asset.
     */
    function _validatePosition(uint256 loan, uint256 collateral, uint256 price) internal view {
        uint256 collateralToBaseCurrency = _convertToBaseCurrency(
            collateral,
            price,
            _decimalsToken1,
            _dataFeedDecimals
        );

        int256 healthFactor = _calcHealth(loan, collateralToBaseCurrency);
        if (healthFactor <= _minHealthPercent) {
            revert TooLowHealth(healthFactor, _minHealthPercent);
        }
    }

    /// @notice Calculates the fees to be charged by the borrower for a given loan and K-value change.
    /// @dev If the change in K-value is zero, this function returns (0, 0).
    /// The commissionBase is calculated as the product of the loan amount and the change in K-value, divided by 100 and multiplied by 1e18 to account for the precision of the numbers.
    /// The commissionQuote is calculated by converting the commissionBase to the quote currency using the current price.
    /// @param loan The amount of the loan.
    /// @param k The previous K-value.
    /// @param currentK The current K-value.
    /// @param price The current price of the underlying asset.
    /// @return commissionBase The fees to be charged in base currency.
    /// @return commissionQuote The fees to be charged in quote currency.
    function _calculateLoanFees(
        uint256 loan,
        uint256 k,
        uint256 currentK,
        uint256 price
    ) internal view returns (uint256 commissionBase, uint256 commissionQuote) {
        uint256 dK = currentK - k;
        if (dK == 0) {
            return (0, 0);
        }

        commissionBase = ((loan * dK) / (100 * 1e18));
        commissionQuote = _convertToQuoteCurrency(commissionBase, price, _dataFeedDecimals);
    }

    /// @notice Calculates the amount to be liquidated based on the loan amount and collateral value.
    /// The reward for the platform and liquidator are then calculated by taking a percentage of the remaining collateral value.
    /// The function returns the amount to be liquidated, the reward for the platform, and the reward for the liquidator.
    /// @param loan The amount of the loan.
    /// @param collateralInBaseCurrency The value of the collateral in base currency.
    /// @return amountToLiquidation The amount to be liquidated.
    /// @return rewPlatform The reward for the platform.
    /// @return rewLiquidator The reward for the liquidator.
    function _calcLiquidation(
        uint256 loan,
        uint256 collateralInBaseCurrency
    ) internal view returns (uint256 amountToLiquidation, uint256 rewPlatform, uint256 rewLiquidator) {
        // Calculate the remaining collateral value after the loan amount
        int256 remains = int256(collateralInBaseCurrency) - int256(loan);

        // Calculate the rewards for the platform and liquidator
        int256 rp = (remains * int256(_rewardPlatformPercent)) / 10000;
        int256 rl = (remains * int256(_rewardLiquidatorPercent)) / 10000;

        int256 b = int256(((_healthPurpose * collateralInBaseCurrency) / 10000));
        int256 c = (((remains - b - rp - rl) * 10000) / int128(_healthPurpose));

        // Convert the amount to be liquidated to an unsigned integer
        amountToLiquidation = c > 0 ? (c).toUint256() : (-c).toUint256();

        return (amountToLiquidation, (rp).toUint256(), (rl).toUint256());
    }

    /// @dev Calculates the current K value of the pool.
    /// The formula for K is `K = borrowRatePerSec * (block.timestamp - lastUpdateRate) + k`, where borrowRatePerSec is the borrow rate per second,
    /// lastUpdateRate is the timestamp of the last borrow rate update, and k is the previous K value.
    /// @return k The current K value of the pool.
    function _calcK() internal view returns (uint256 k) {
        return _borrowRatePerSec * (block.timestamp - _lastUpdateRate) + _k;
    }

    /// function calculate health factor
    function _calcHealth(uint256 loan, uint256 collateralInBaseCurrency) internal view returns (int256 healthFactor) {
        if (loan == 0 && collateralInBaseCurrency == 0) {
            return 0;
        }
        return
            ((int256(collateralInBaseCurrency) - int256(loan)) *
                int256(10000 - _rewardLiquidatorPercent - _rewardPlatformPercent)) / int256(collateralInBaseCurrency);
    }

    /// @dev Calculates the reward for extra liquidation.
    /// The function returns the fixed reward for extra liquidation set by the configurator.
    /// @return The reward for extra liquidation.
    function _rewardForExtraLiquidation() internal view returns (uint256) {
        return _extraReward;
    }

    /// @notice Converts an amount of a token to its base currency equivalent.
    /// The function takes an amount of a token and the current price of the token and returns the equivalent amount in base currency.
    /// @param amount The amount of the token to be converted.
    /// @param price The current price of the token.
    /// @return amountInBaseCurrency The equivalent amount of the token in base currency.
    function _convertToBaseCurrency(
        uint256 amount,
        uint256 price,
        uint256 decimalsToken,
        uint256 dataFeedDecimals
    ) internal pure returns (uint256 amountInBaseCurrency) {
        uint256 convertPrice = (10 ** decimalsToken * price) / 10 ** dataFeedDecimals;
        amountInBaseCurrency = (amount * convertPrice) / 10 ** decimalsToken;
    }

    /// @notice Converts an amount of a token to its quote currency equivalent.
    /// The function takes an amount of a token and the current price of the token and returns the equivalent amount in quote currency.
    /// @param amount The amount of the token to be converted.
    /// @param price The current price of the token.
    /// @return amountInQuoteCurrency The equivalent amount of the token in quote currency.
    function _convertToQuoteCurrency(
        uint256 amount,
        uint256 price,
        uint256 dataFeedDecimals
    ) internal pure returns (uint256 amountInQuoteCurrency) {
        return (amount * 10 ** dataFeedDecimals) / price;
    }
}
