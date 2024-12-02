// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IPool {
    struct Position {
        uint128 collateral;
        uint128 loan;
        uint256 k;
    }

    event HealthRewardConfigUpdated(
        uint256 minHealthPercent,
        uint256 liquidateHealthPercent,
        uint128 healthPurpose,
        uint256 rewardLiquidatorPercent,
        uint256 rewardPlatformPercent
    );
    event BorrowRateUpdated(uint256 borrowRatePerSec);
    event ConfigUpdated(address dataFeed, uint256 acceptableTimeInterval);

    error TooLowHealth(int256 health, int256 minHealth);
    error PositionNotInLiquidationZone(int256 health, int256 liquidationMinHealth);
    error PositionEmpty(uint256 id);
    error OnlyAdapter();
    error OnlyConfigurator();
    error OracleOldPrice(uint256 updatedAt, uint256 time);
    error InvalidRepayment(uint128 loan, uint128 collateral);
    error NotExtraLiquidate(int256 healthFactor);
    error PositionUnderwater();
    error PositionNotUnderwater(int256 healthFactor);
    error InvalidRewardConfig();
    error ZeroAddress();
    error LoanLessThanMinLoan(uint256 loan, uint256 _minLoan);
    error InvalidHealthPurpose(uint256 sum);

    /// Pauses the contract. Only the configurator can pause it.
    function pause() external;

    /// Unpauses the contract. Only the configurator can unpause it.
    function unpause() external;

    /// @dev Sets the extra reward. Only the configurator can set it.
    /// @param extraReward fixed reward for extra liquidation.
    function setExtraReward(uint256 extraReward) external;

    /// @dev Set the borrow rate of the contract. Only the configurator can set it.
    /// The precision of the borrow rate is 18.
    /// Example 5% = 5e18
    /// @notice The borrow rate is the annual interest rate that borrowers pay to lenders.
    /// The function converts the borrow rate per year to a borrow rate per second.
    /// The borrow rate is stored in `_borrowRatePerSec` and `_lastUpdateRate` is updated to the current block timestamp.
    function setBorrowRate(uint256 borrowRatePerYear) external;

    function setHealthRewardConfig(
        uint256 newMinHealthPercent,
        uint256 newLiquidateHealthPercent,
        uint128 newHealthPurpose,
        uint256 newRewardLiquidatorPercent,
        uint256 newRewardPlatformPercent
    ) external;

    function setMinLoan(uint256 newMinLoan) external;

    /// Creates a new position with the given `loan` and `collateral` amounts.
    /// @param loan The amount of the loan to be borrowed.
    /// @param collateral The amount of collateral to be put up as collateral.
    /// @param posId The ID of the new position.
    function borrow(uint128 loan, uint128 collateral, uint256 posId) external;

    /// Adds more loan and collateral to an existing position.
    /// This function allows a user to add more loan and collateral to an existing position.
    /// @param posId The ID of the position to add more loan and collateral to.
    /// @param collateral The amount of collateral to add to the position.
    /// @param loan The amount of loan to add to the position.
    function borrowMore(uint256 posId, uint128 collateral, uint128 loan) external returns (uint256 commissionQuote);

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
    ) external returns (uint256, bool isClosePosition, uint256 commissionQuote);

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
        returns (uint256 liqLoan, uint128 liqColl, uint256 rewPlatform, uint256 rewLiquidator, uint256 commissionQuote);

    /// Extra liquidation of the position. This works if the operability of the position is below zero
    /// @param posId The ID of the position to be liquidated.
    /// @return liqLoan The total amount of loan to be liquidated.
    /// @return liqColl The total amount of collateral to be liquidated.
    /// @return extraReward The additional reward given to the liquidator for extra liquidation.
    /// @return loss The loss incurred by the platform.
    function extraLiquidate(
        uint256 posId
    ) external returns (uint256 liqLoan, uint128 liqColl, uint256 extraReward, int256 loss);

    /// @notice Returns the current K value of the pool.
    /// @return The current K value.
    function getCurrentK() external view returns (uint256);

    /// @notice Returns the health configuration of the pool.
    /// @return minHealthPercent The minimum health percentage.
    /// @return liquidateHealthPercent The liquidation health percentage.
    /// @return healthPurpose The health purpose.
    function getHealthConfig()
        external
        view
        returns (int256 minHealthPercent, int256 liquidateHealthPercent, uint128 healthPurpose);

    /// @notice Returns the reward configuration of the pool.
    /// @return rewardLiquidatorPercent The percentage of rewards for liquidators.
    /// @return rewardPlatformPercent The percentage of rewards for the platform.
    function getRewardConfig() external view returns (uint256 rewardLiquidatorPercent, uint256 rewardPlatformPercent);

    /// @notice Returns the borrow rate information of the pool.
    /// @return borrowRatePerSec The borrow rate per second.
    /// @return lastUpdateRate The timestamp of the last borrow rate update.
    function getBorrowRateInfo() external view returns (uint256 borrowRatePerSec, uint256 lastUpdateRate);

    /// @notice Returns the acceptable time interval of the chainlink
    function getAcceptableTimeInterval() external view returns (uint256);

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
        returns (Position memory position, int256 healthFactor, uint256 commissionBase, uint256 commissionQuote);

    /// @notice Returns the token addresses of the pool.
    /// @return token0 The address of the first token.
    /// @return token1 The address of the second token.
    function getTokens() external view returns (address token0, address token1);

    /// @notice Calculates the health factor of a position.
    /// @param posId The ID of the position.
    /// @return healthFactor The health factor of the position.
    function getPositionHealth(uint256 posId) external view returns (int256 healthFactor);
}
