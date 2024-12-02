// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {PausableUpgradeable} from '@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol';

import {IConfigurator} from './interfaces/IConfigurator.sol';
import {IPool, IAdapter} from './interfaces/IAdapter.sol';
import {ITreasure} from './interfaces/ITreasure.sol';

import {IERC20, UniversalTransfer} from '../lending/UniversalTransfer.sol';

contract Adapter is IAdapter, Initializable, PausableUpgradeable {
    using UniversalTransfer for IERC20;

    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev account => token => InfoCollateral
    mapping(address => mapping(address => InfoCollateral)) private _userCollateralByToken;

    /// @dev idPos => InfoPosition
    mapping(uint256 => InfoPosition) private _positionInfoById;

    uint256 public counterId;
    IConfigurator internal _configurator;
    address payable internal _treasure;
    uint256 public entryFee;

    modifier onlyConfigurator() {
        if (msg.sender != address(_configurator)) {
            revert OnlyConfigurator();
        }
        _;
    }

    /**
     * @dev Initializes the Adapter contract.
     * @param addrConfigurator The address of the Configurator contract.
     * @param addrTreasure The address of the Treasure contract.
     */
    function initialize(address addrConfigurator, address payable addrTreasure) external override initializer {
        if (addrConfigurator == address(0) || addrTreasure == address(0)) {
            revert ZeroAddress();
        }
        _configurator = IConfigurator(addrConfigurator);
        _treasure = addrTreasure;
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

    function setEntryFee(uint256 fee) external override onlyConfigurator {
        entryFee = fee;
    }

    /// @notice Supplies collateral to the contract.
    /// @dev This function can only be called when the contract is not paused.
    /// @param token The address of the collateral token.
    /// @param amount The amount of collateral to supply.
    function supply(address token, uint256 amount) external payable override whenNotPaused {
        if (!_configurator.isToken(token)) {
            revert InvalidToken();
        }
        uint256 tax = 0;
        if (entryFee > 0) {
            tax = (amount * entryFee) / 10_000;
        }
        InfoCollateral storage infoCollateral = _userCollateralByToken[token][msg.sender];
        infoCollateral.collateral += (amount - tax);
        // Transfer the collateral from the user to the contract
        IERC20(token).universalTransferFrom(msg.sender, _treasure, amount - tax);
        ITreasure(_treasure).addCollateral(token, amount - tax);
        emit Supply({token: token, account: msg.sender, amount: amount - tax, tax: tax});
    }

    /// @notice Withdraws collateral from the contract.
    /// @dev This function can only be called when the contract is not paused.
    /// @param token The address of the collateral token.
    /// @param amount The amount of collateral to withdraw.
    function withdrawCollateral(address token, uint256 amount) external override whenNotPaused {
        InfoCollateral storage infoCollateral = _userCollateralByToken[token][msg.sender];
        uint256 availableCollateral = _calcAvailableCollateral(infoCollateral);
        if (availableCollateral < amount) {
            revert InsufficientCollateral(availableCollateral);
        }
        infoCollateral.collateral -= amount;
        ITreasure(_treasure).transferTo(token, msg.sender, amount);
        ITreasure(_treasure).subCollateral(token, amount);
        emit WithdrawCollateral({token: token, account: msg.sender, amount: amount});
    }

    /// @notice Allows a user to borrow a certain amount of USD3 tokens by providing collateral.
    /// @dev This function can only be called when the contract is not paused.
    /// @param token0 The address of the first collateral token.
    /// @param token1 The address of the second collateral token.
    /// @param loan The amount of USD3 tokens to borrow.
    /// @param provision The amount of collateral to provide.
    function borrow(
        address token0,
        address token1,
        uint128 loan,
        uint128 provision
    ) external payable override whenNotPaused {
        address pool = _configurator.getPool(token0, token1);
        if (pool == address(0)) {
            revert InvalidPool();
        }

        InfoCollateral storage infoCollateral = _userCollateralByToken[token1][msg.sender];
        uint256 availableCollateral = _calcAvailableCollateral(infoCollateral);
        if (availableCollateral < provision) {
            revert InsufficientCollateral(availableCollateral);
        }
        infoCollateral.usedCollateral += provision;

        uint256 idPos = counterId;
        IPool(pool).borrow(loan, provision, idPos);

        _positionInfoById[idPos] = InfoPosition({pool: pool, account: msg.sender, status: PositionStatus.OPEN});
        emit Borrow({positionId: idPos, pool: pool, loan: loan, provision: provision});

        ITreasure(_treasure).transferTo(token0, msg.sender, loan);

        counterId++;
    }

    /// @notice Allows a user to borrow more USD3 tokens by providing additional collateral.
    /// @dev This function can only be called when the contract is not paused.
    /// @param idPosition The ID of the position to borrow from.
    /// @param addCollateral The amount of additional collateral to provide.
    /// @param addLoan The amount of additional USD3 tokens to borrow.
    function borrowMore(uint256 idPosition, uint128 addCollateral, uint128 addLoan) external override whenNotPaused {
        InfoPosition storage infoPosition = _positionInfoById[idPosition];

        _validatePosition(infoPosition, idPosition);

        (address token0, address token1) = IPool(infoPosition.pool).getTokens();
        InfoCollateral storage infoCollateral = _userCollateralByToken[token1][msg.sender];

        uint256 availableCollateral = _calcAvailableCollateral(infoCollateral);
        if (availableCollateral < addCollateral) {
            revert InsufficientCollateral(availableCollateral);
        }

        uint256 commissionQuote = IPool(infoPosition.pool).borrowMore(idPosition, addCollateral, addLoan);
        infoCollateral.usedCollateral = infoCollateral.usedCollateral + addCollateral - commissionQuote;
        infoCollateral.collateral -= commissionQuote;

        emit BorrowMore({
            positionId: idPosition,
            pool: infoPosition.pool,
            addCollateral: addCollateral,
            addLoan: addLoan
        });
        // Transfer the loan from treasure to user
        ITreasure(_treasure).transferTo(token0, msg.sender, addLoan);

        ITreasure(_treasure).addTax(token1, 0, commissionQuote);
    }

    /// @notice Repay function allows a user to repay the loan.
    /// @param idPosition ID of the position to repay
    /// @param loanRepayment the amount of loan to repay
    /// @param refundCollateral the amount of collateral to refund.
    /// @dev This function can only be called when the contract is not paused.
    /// It checks the position status and validates the position.
    /// It also calculates the refund collateral and commission quote.
    /// If the position is closed, it updates the position status.
    /// It updates the used collateral and collateral of the InfoCollateral struct.
    function repay(
        uint256 idPosition,
        uint128 loanRepayment,
        uint128 refundCollateral
    ) external payable override whenNotPaused {
        InfoPosition storage infoPosition = _positionInfoById[idPosition];

        _validatePosition(infoPosition, idPosition);

        (address token0, address token1) = IPool(infoPosition.pool).getTokens();
        (uint256 refundColl, bool isClosePosition, uint256 commissionQuote) = IPool(infoPosition.pool).repay(
            loanRepayment,
            idPosition,
            refundCollateral
        );
        if (isClosePosition) {
            infoPosition.status = PositionStatus.CLOSED;
        }

        InfoCollateral storage infoCollateral = _userCollateralByToken[token1][msg.sender];
        infoCollateral.usedCollateral -= (refundColl + commissionQuote);
        infoCollateral.collateral -= commissionQuote;
        IERC20(token0).universalTransferFrom(msg.sender, _treasure, loanRepayment);
        ITreasure(_treasure).addTax(token1, 0, commissionQuote);

        emit Repay({
            positionId: idPosition,
            loanRepayment: loanRepayment,
            refundCollateral: refundColl,
            statusPosition: infoPosition.status
        });
    }

    /// @dev This function can only be called when the contract is not paused.
    /// It liquidates the position specified by the `idPosition` parameter.
    /// It checks if the position is open and if not, it reverts.
    /// It calculates the liquidation loan, liquidation collateral, platform reward, liquidator reward, and commission quote.
    /// It updates the used collateral and collateral of the InfoCollateral struct.
    function liquidate(uint256 idPosition) external payable override whenNotPaused {
        InfoPosition storage infoPosition = _positionInfoById[idPosition];
        if (infoPosition.status != PositionStatus.OPEN) {
            revert NotOpenPosition(idPosition);
        }
        (, address token1) = IPool(infoPosition.pool).getTokens();
        (uint256 liqLoan, uint128 liqColl, uint256 rewPlatform, uint256 rewLiquidator, uint256 commissionQuote) = IPool(
            infoPosition.pool
        ).liquidate(idPosition);

        InfoCollateral storage infoCollateral = _userCollateralByToken[token1][infoPosition.account];

        infoCollateral.usedCollateral -= (liqColl + commissionQuote);
        infoCollateral.collateral -= (liqColl + commissionQuote);

        emit Liquidate({
            positionId: idPosition,
            liqLoan: liqLoan,
            liqColl: liqColl,
            pool: infoPosition.pool,
            rewardLiquidator: rewLiquidator,
            rewardPlatform: rewPlatform
        });
        ITreasure(_treasure).addTax(token1, rewPlatform, commissionQuote);
        ITreasure(_treasure).transferTo(token1, msg.sender, rewLiquidator);
        ITreasure(_treasure).addLiquidateCollateral(token1, liqColl);
    }

    function extraLiquidate(uint256 idPosition) external override whenNotPaused {
        InfoPosition storage infoPosition = _positionInfoById[idPosition];
        if (infoPosition.status != PositionStatus.OPEN) {
            revert NotOpenPosition(idPosition);
        }
        (, address token1) = IPool(infoPosition.pool).getTokens();
        (uint256 liqLoan, uint128 liqColl, uint256 extraReward, int256 loss) = IPool(infoPosition.pool).extraLiquidate(
            idPosition
        );

        InfoCollateral storage infoCollateral = _userCollateralByToken[token1][infoPosition.account];
        infoCollateral.usedCollateral -= liqColl;
        infoCollateral.collateral -= liqColl;
        infoPosition.status = PositionStatus.CLOSED;

        emit ExtraLiquidate({
            positionId: idPosition,
            liqLoan: liqLoan,
            liqColl: liqColl,
            pool: infoPosition.pool,
            rewardLiquidator: extraReward,
            loss: loss
        });

        ITreasure(_treasure).transferTo(token1, msg.sender, extraReward);
        ITreasure(_treasure).addLoss(token1, loss + int256(extraReward));
        ITreasure(_treasure).addLiquidateCollateral(token1, liqColl);
    }

    /// @notice This function allows to retrieve the collateral information and the available collateral amount for a given token and account.
    /// @dev It returns an InfoCollateral struct and the available collateral amount for the given parameters.
    /// @param token The address of the collateral token.
    /// @param account The address of the account.
    /// @return infoCollateral The InfoCollateral struct containing the collateral information.
    /// @return availableCollateral The available collateral amount for the given token and account.
    function getInfoCollateral(
        address token,
        address account
    ) external view override returns (InfoCollateral memory, uint256 availableCollateral) {
        InfoCollateral storage infoCollateral = _userCollateralByToken[token][account];
        return (infoCollateral, _calcAvailableCollateral(infoCollateral));
    }

    /// @notice This function returns the full information of a position, including the position's details,
    /// health factor, base currency commission, and quote currency commission.
    /// @dev It calls the `getInfoPosition` function of the `IPool` contract to retrieve the position details and the
    /// health factor. It then retrieves the base currency and quote currency commissions.
    /// @param idPosition The ID of the position.
    /// @return infoPosition The `InfoPosition` struct containing the position's details.
    /// @return position The `Position` struct containing the position's details.
    /// @return health The health factor of the position.
    /// @return commissionBase The base currency commission.
    /// @return commissionQuote The quote currency commission.
    function getFullInfoPosition(
        uint256 idPosition
    )
        external
        view
        override
        returns (
            InfoPosition memory infoPosition,
            IPool.Position memory position,
            int256 health,
            uint256 commissionBase,
            uint256 commissionQuote
        )
    {
        infoPosition = _positionInfoById[idPosition];
        (position, health, commissionBase, commissionQuote) = IPool(infoPosition.pool).getInfoPosition(idPosition);
    }

    /// @notice This function returns information about collateral of a position.
    /// @dev It retrieves the position's details from the `_positionInfoById` mapping.
    /// @param idPosition The ID of the position.
    /// @return infoPosition The `InfoPosition` struct containing the position's details.
    function getInfoPosition(uint256 idPosition) external view override returns (InfoPosition memory infoPosition) {
        infoPosition = _positionInfoById[idPosition];
    }

    /// @notice This internal function calculates the available collateral amount for a given `InfoCollateral` struct.
    /// @dev It subtracts the `usedCollateral` from the `collateral` field of the `infoCollateral` parameter.
    /// @param infoCollateral The `InfoCollateral` struct to calculate the available collateral for.
    /// @return availableCollateral The available collateral amount.
    function _calcAvailableCollateral(
        InfoCollateral storage infoCollateral
    ) internal view returns (uint256 availableCollateral) {
        return (infoCollateral.collateral - infoCollateral.usedCollateral);
    }

    /// @notice This internal function validates a position by checking its details.
    /// @dev It checks if the position's pool is not zero, if the position's status is OPEN,
    /// and if the owner of the position is the caller.
    /// @param infoPosition The `InfoPosition` struct to validate.
    /// @param idPosition The ID of the position.
    function _validatePosition(InfoPosition storage infoPosition, uint256 idPosition) internal view {
        if (infoPosition.pool == address(0)) {
            revert InvalidPool();
        }
        if (infoPosition.status != PositionStatus.OPEN) {
            revert NotOpenPosition(idPosition);
        }
        if (infoPosition.account != msg.sender) {
            revert OnlyOwnerPosition(infoPosition.account);
        }
    }
}
