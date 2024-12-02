// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

library UniversalTransfer {
    using SafeERC20 for IERC20;

    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private constant ZERO_ADDRESS = 0x0000000000000000000000000000000000000000;

    error NativeTransferFailed();
    error InsufficientBalance();

    function universalTransfer(IERC20 token, address to, uint256 amount) internal {
        if (isETH(token)) {
            if (address(this).balance < amount) {
                revert InsufficientBalance();
            }
            (bool success, ) = to.call{value: amount, gas: 50e6}('');
            if (!success) {
                revert NativeTransferFailed();
            }
        } else {
            token.safeTransfer(to, amount);
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (isETH(token)) {
            if (amount != msg.value) {
                revert InsufficientBalance();
            }
            (bool success, ) = to.call{value: amount}('');
            if (!success) {
                revert NativeTransferFailed();
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (!isETH(token)) {
            token.forceApprove(to, amount);
            return;
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return (address(token) == address(ZERO_ADDRESS) || address(token) == address(NATIVE));
    }
}
