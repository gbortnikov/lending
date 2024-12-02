// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IPool} from './IPool.sol';

interface IAdapter {
    enum PositionStatus {
        NOT_CREATED,
        OPEN,
        CLOSED
    }

    struct InfoCollateral {
        uint256 collateral;
        uint256 usedCollateral;
    }
    struct InfoPosition {
        address pool;
        address account;
        PositionStatus status;
    }

    event Supply(address account, address token, uint256 amount, uint256 tax);
    event WithdrawCollateral(address account, address token, uint256 amount);
    event Borrow(uint256 positionId, address pool, uint256 loan, uint256 provision);
    event BorrowMore(uint256 positionId, address pool, uint256 addCollateral, uint256 addLoan);
    event Repay(uint256 positionId, uint256 loanRepayment, uint256 refundCollateral, PositionStatus statusPosition);
    event Liquidate(
        uint256 positionId,
        uint256 liqLoan,
        uint256 liqColl,
        address pool,
        uint256 rewardLiquidator,
        uint256 rewardPlatform
    );

    event ExtraLiquidate(
        uint256 positionId,
        uint256 liqLoan,
        uint256 liqColl,
        address pool,
        uint256 rewardLiquidator,
        int256 loss
    );

    error OnlyConfigurator();
    error InsufficientCollateral(uint256 availableCollateral);
    error InvalidToken();
    error InvalidPool();
    error OnlyPool();
    error OnlyOwnerPosition(address account);
    error NotOpenPosition(uint256 idPosition);
    error ZeroAddress();

    /**
     * @dev Initializes the Adapter contract.
     * @param addrConfigurator The address of the Configurator contract.
     * @param addrTreasure The address of the Treasure contract.
     */
    function initialize(address addrConfigurator, address payable addrTreasure) external;

    /// Pauses the contract. Only the configurator can pause it.
    function pause() external;

    /// Unpauses the contract. Only the configurator can unpause it.
    function unpause() external;

    function setEntryFee(uint256 fee) external;

    /// @notice Supplies collateral to the contract.
    /// @dev This function can only be called when the contract is not paused.
    /// @param token The address of the collateral token.
    /// @param amount The amount of collateral to supply.
    function supply(address token, uint256 amount) external payable;

    /// @notice Withdraws collateral from the contract.
    /// @dev This function can only be called when the contract is not paused.
    /// @param token The address of the collateral token.
    /// @param amount The amount of collateral to withdraw.
    function withdrawCollateral(address token, uint256 amount) external;

    /// @notice Allows a user to borrow a certain amount of USD3 tokens by providing collateral.
    /// @dev This function can only be called when the contract is not paused.
    /// @param token0 The address of the first collateral token.
    /// @param token1 The address of the second collateral token.
    /// @param loan The amount of USD3 tokens to borrow.
    /// @param provision The amount of collateral to provide.
    function borrow(address token0, address token1, uint128 loan, uint128 provision) external payable;

    /// @notice Allows a user to borrow more USD3 tokens by providing additional collateral.
    /// @dev This function can only be called when the contract is not paused.
    /// @param idPosition The ID of the position to borrow from.
    /// @param addCollateral The amount of additional collateral to provide.
    /// @param addLoan The amount of additional USD3 tokens to borrow.
    function borrowMore(uint256 idPosition, uint128 addCollateral, uint128 addLoan) external;

    /// @notice Repay function allows a user to repay the loan.
    /// @param idPosition ID of the position to repay
    /// @param loanRepayment the amount of loan to repay
    /// @param refundCollateral the amount of collateral to refund.
    /// @dev This function can only be called when the contract is not paused.
    function repay(uint256 idPosition, uint128 loanRepayment, uint128 refundCollateral) external payable;

    /// @dev This function can only be called when the contract is not paused.
    /// It liquidates the position specified by the `idPosition` parameter.
    function liquidate(uint256 idPosition) external payable;

    function extraLiquidate(uint256 idPosition) external;

    /// @notice This function allows to retrieve the collateral information and the available collateral amount for a given token and account.
    /// @dev It returns an InfoCollateral struct and the available collateral amount for the given parameters.
    /// @param token The address of the collateral token.
    /// @param account The address of the account.
    /// @return infoCollateral The InfoCollateral struct containing the collateral information.
    /// @return availableCollateral The available collateral amount for the given token and account.
    function getInfoCollateral(
        address token,
        address account
    ) external view returns (InfoCollateral memory, uint256 availableCollateral);

    /// @notice This function returns the full information of a position, including the position's details, health factor,
    /// base currency commission, and quote currency commission.
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
        returns (
            InfoPosition memory infoPosition,
            IPool.Position memory position,
            int256 health,
            uint256 commissionBase,
            uint256 commissionQuote
        );

    /// @notice This function returns information about collateral of a position.
    /// @param idPosition The ID of the position.
    /// @return infoPosition The `InfoPosition` struct containing the position's details.
    function getInfoPosition(uint256 idPosition) external view returns (InfoPosition memory infoPosition);

    function entryFee() external view returns (uint256);
}
