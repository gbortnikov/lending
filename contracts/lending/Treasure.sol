// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

import {ITreasure} from './interfaces/ITreasure.sol';

import {IERC20, UniversalTransfer} from '../lending/UniversalTransfer.sol';

contract Treasure is ITreasure, Initializable {
    using UniversalTransfer for IERC20;

    address internal _configurator;
    address internal _adapter;

    mapping(address => uint256) internal _tokenTaxLiquidate;
    mapping(address => uint256) internal _tokenTaxBorrow;
    mapping(address => int256) internal _tokenLoss;
    mapping(address => uint256) internal _tokenTotalSupply;
    mapping(address => uint256) internal _tokenLiquidatedCollateral;

    modifier onlyConfigurator() {
        if (msg.sender != _configurator) {
            revert OnlyConfigurator();
        }
        _;
    }
    modifier onlyAdapter() {
        if (msg.sender != _adapter) {
            revert OnlyAdapter();
        }
        _;
    }

    function initialize(address configurator, address adapter) external override initializer {
        if (configurator == address(0) || adapter == address(0)) {
            revert ZeroAddress();
        }

        _configurator = configurator;
        _adapter = adapter;
    }

    receive() external payable override {}

    /// @dev This function allows the configurator to replenish the losses for a given token.
    /// It adds the specified amount to the total losses of the token.
    /// @param token The token for which the losses are being replenished.
    /// @param amount The amount of losses to replenish.
    function replenishLosses(address token, uint256 amount) external override onlyConfigurator {
        _tokenLoss[token] += int256(amount);
        emit ReplenishLosses({token: token, amount: amount});
    }

    /// @dev Transfers tokens from the treasury to another address.
    /// Only the adapter can call this function
    /// @param token The token to transfer.
    /// @param to The address to transfer the tokens to.
    /// @param amount The amount of tokens to transfer.
    function transferTo(address token, address to, uint256 amount) external override onlyAdapter {
        IERC20(token).universalTransfer(to, amount);
    }

    /// @dev Withdraws liquidate tax from the treasury.
    /// Only the configurator can call this function
    /// @param token The token to withdraw the tax from.
    /// @param to The address to transfer the tax to.
    /// @param amount The amount of tax to withdraw.
    function withdrawTaxLiquidate(address token, address to, uint256 amount) external override onlyConfigurator {
        _tokenTaxLiquidate[token] -= amount;
        IERC20(token).universalTransfer(to, amount);

        emit WithdrawTaxLiquidate({token: token, account: to, amount: amount});
    }

    /// @dev Withdraws borrowing tax from the treasury.
    /// Only the configurator can call this function.
    /// @param token The token to withdraw the tax from.
    /// @param to The address to transfer the tax to.
    /// @param amount The amount of tax to withdraw.
    function withdrawTaxBorrow(address token, address to, uint256 amount) external override onlyConfigurator {
        _tokenTaxBorrow[token] -= amount;
        IERC20(token).universalTransfer(to, amount);

        emit WithdrawTaxBorrow({token: token, account: to, amount: amount});
    }

    function withdrawLiquidateCollateral(address token, address to, uint256 amount) external override onlyConfigurator {
        _tokenLiquidatedCollateral[token] -= amount;
        IERC20(token).universalTransfer(to, amount);

        emit WithdrawLiquidateCollateral({token: token, account: to, amount: amount});
    }

    /// @dev Deposits tokens into the treasury.
    /// Only the configurator can call this function.
    /// @param token The token to deposit.
    /// @param amount The amount of tokens to deposit.
    function refund(address token, address account, uint256 amount) external override onlyConfigurator {
        emit Refund({token: token, account: account, amount: amount});
    }

    /// @dev Withdraws tokens from the treasury.
    /// Only the configurator can call this function.
    /// @param token The token to withdraw.
    /// @param to The address to transfer the tokens to.
    /// @param amount The amount of tokens to withdraw.
    function investCollateral(address token, address to, uint256 amount) external override onlyConfigurator {
        IERC20(token).universalTransfer(to, amount);
        emit Withdraw({token: token, account: to, amount: amount});
    }

    /// @dev Adds taxes for liquidation and borrowing for a given token.
    /// Only the adapter can call this function
    /// @param token The token to add taxes for.
    /// @param taxLiquidate The amount of tax to add for liquidation.
    /// @param taxBorrow The amount of tax to add for borrowing.
    function addTax(address token, uint256 taxLiquidate, uint256 taxBorrow) external override onlyAdapter {
        if (taxLiquidate > 0) {
            _addTaxLiquidate(token, taxLiquidate);
        }
        if (taxBorrow > 0) {
            _addTaxBorrow(token, taxBorrow);
        }
        emit AddTax({token: token, taxLiquidate: taxLiquidate, taxBorrow: taxBorrow});
    }

    /// @dev Adds a loss to the treasury for a given token.
    /// Only the adapter can call this function.
    /// @param token The token to add loss for.
    /// @param loss The amount of loss to add.
    function addLoss(address token, int256 loss) external override onlyAdapter {
        _tokenLoss[token] += loss;
        emit AddLoss({token: token, loss: loss});
    }

    function addCollateral(address token, uint256 amount) external onlyAdapter {
        _tokenTotalSupply[token] += amount;
    }

    function subCollateral(address token, uint256 amount) external onlyAdapter {
        _tokenTotalSupply[token] -= amount;
    }

    function addLiquidateCollateral(address token, uint256 amount) public override onlyAdapter {
        _tokenLiquidatedCollateral[token] += amount;
        _tokenTotalSupply[token] -= amount;
    }

    /**
     * @dev Returns the liquidate and borrow taxes for a given token.
     * @param token The token to get the taxes for.
     * @return taxLiquidate The liquidate tax for the token.
     * @return taxBorrow The borrow tax for the token.
     */
    function getTax(address token) external view override returns (uint256 taxLiquidate, uint256 taxBorrow) {
        return (_tokenTaxLiquidate[token], _tokenTaxBorrow[token]);
    }

    /**
     * @dev Returns the balance of a given token in the treasury.
     * @param token The token to get the balance of.
     * @return The balance of the token in the treasury.
     */
    function balanceOf(address token) external view override returns (uint256) {
        if (UniversalTransfer.NATIVE == token) {
            return address(this).balance;
        }
        return IERC20(token).balanceOf(address(this));
    }

    /// @dev Returns the addresses of the configurator and adapter.
    /// @return configurator The address of the configurator.
    /// @return adapter The address of the adapter.
    function getAddresses() external view override returns (address, address) {
        return (_configurator, _adapter);
    }

    /// @dev Adds the liquidate tax for a given token.
    /// @param token The token to add the tax for.
    /// @param amount The amount of tax to add.
    function _addTaxLiquidate(address token, uint256 amount) internal {
        _tokenTaxLiquidate[token] += amount;
    }

    /// @dev Adds the borrow tax for a given token.
    /// @param token The token to add the tax for.
    /// @param amount The amount of tax to add.
    function _addTaxBorrow(address token, uint256 amount) internal {
        _tokenTaxBorrow[token] += amount;
    }
}
