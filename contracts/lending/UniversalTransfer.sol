// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, SafeERC20} from '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

library UniversalTransfer {
    using SafeERC20 for IERC20;

    address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    error NativeTransferFailed();
    error InsufficientBalance();

    function universalTransfer(IERC20 token, address to, uint256 amount) internal {
        if (NATIVE == address(token)) {
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
        if (NATIVE == address(token)) {
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
}
