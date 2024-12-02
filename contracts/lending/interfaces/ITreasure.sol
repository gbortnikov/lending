// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITreasure {
    event AddTax(address indexed token, uint256 taxLiquidate, uint256 taxBorrow);

    event Withdraw(address indexed token, address indexed account, uint256 amount);
    event Refund(address token, address account, uint256 amount);
    event WithdrawTaxLiquidate(address indexed token, address indexed account, uint256 amount);
    event WithdrawTaxBorrow(address indexed token, address indexed account, uint256 amount);
    event WithdrawLiquidateCollateral(address indexed token, address indexed account, uint256 amount);
    event AddLoss(address indexed token, int256 loss);
    event ReplenishLosses(address token, uint256 amount);

    error OnlyConfigurator();
    error OnlyAdapter();
    error ZeroAddress();

    receive() external payable;

    function initialize(address configurator, address adapter) external;

    /// @dev Adds taxes for liquidation and borrowing for a given token.
    /// @param token The token to add taxes for.
    /// @param taxLiquidate The amount of tax to add for liquidation.
    /// @param taxBorrow The amount of tax to add for borrowing.
    function addTax(address token, uint256 taxLiquidate, uint256 taxBorrow) external;

    function addLoss(address token, int256 loss) external;

    function addCollateral(address token, uint256 amount) external;

    function subCollateral(address token, uint256 amount) external;

    function addLiquidateCollateral(address token, uint256 amount) external;

    function replenishLosses(address token, uint256 amount) external;

    /// @dev Transfers tokens from the treasury to another address.
    /// @param token The token to transfer.
    /// @param to The address to transfer the tokens to.
    /// @param amount The amount of tokens to transfer.
    function transferTo(address token, address to, uint256 amount) external;

    /// @dev Withdraws liquidate tax from the treasury.
    /// @param token The token to withdraw the tax from.
    /// @param to The address to transfer the tax to.
    /// @param amount The amount of tax to withdraw.
    function withdrawTaxLiquidate(address token, address to, uint256 amount) external;

    /// @dev Withdraws borrowing tax from the treasury.
    /// @param token The token to withdraw the tax from.
    /// @param to The address to transfer the tax to.
    /// @param amount The amount of tax to withdraw.
    function withdrawTaxBorrow(address token, address to, uint256 amount) external;

    function withdrawLiquidateCollateral(address token, address to, uint256 amount) external;

    /// @dev Deposits tokens into the treasury.
    /// @param token The token to deposit.
    /// @param amount The amount of tokens to deposit.
    function refund(address token, address account, uint256 amount) external;

    /// @dev Withdraws tokens from the treasury.
    /// @param token The token to withdraw.
    /// @param to The address to transfer the tokens to.
    /// @param amount The amount of tokens to withdraw.
    function investCollateral(address token, address to, uint256 amount) external;

    /**
     * @dev Returns the liquidate and borrow taxes for a given token.
     * @param token The token to get the taxes for.
     * @return taxLiquidate The liquidate tax for the token.
     * @return taxBorrow The borrow tax for the token.
     */
    function getTax(address token) external view returns (uint256 taxLiquidate, uint256 taxBorrow);

    /**
     * @dev Returns the balance of a given token in the treasury.
     * @param token The token to get the balance of.
     * @return The balance of the token in the treasury.
     */
    function balanceOf(address token) external view returns (uint256);

    /// @dev Returns the addresses of the configurator and adapter.
    /// @return configurator The address of the configurator.
    /// @return adapter The address of the adapter.
    function getAddresses() external view returns (address, address);
}
