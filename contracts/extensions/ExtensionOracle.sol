// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {IUniswapV3Pool, IUniswapV3PoolState} from '@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol';
import {TickMath} from '@uniswap/v3-core/contracts/libraries/TickMath.sol';
import {FullMath} from '@uniswap/v3-core/contracts/libraries/FullMath.sol';

library ExtensionOracle {
    /**
     * @dev Returns the TWAP (Time Weighted Average Price) of a pool for the given twapDuration
     * @param pool The address of the Uniswap V3 pool
     * @param twapDuration The duration of the time window for which the TWAP is calculated, in seconds
     * @return twap The TWAP of the pool, as a 24-bit integer
     */
    function _getTwap(address pool, uint32 twapDuration) internal view returns (int24 twap) {
        uint32[] memory secondsAgo = new uint32[](2);
        secondsAgo[0] = twapDuration;
        secondsAgo[1] = 0;

        (int56[] memory tickCumulatives, ) = IUniswapV3Pool(pool).observe(secondsAgo);
        twap = int24((tickCumulatives[1] - tickCumulatives[0]) / int56(uint56(secondsAgo[0])));
    }

    function _getQuoteAtTick(
        int24 tick,
        uint128 baseAmount,
        address baseToken,
        address quoteToken
    ) internal pure returns (uint256 quoteAmount) {
        uint160 sqrtRatioX96 = TickMath.getSqrtRatioAtTick(tick);

        // Calculate quoteAmount with better precision if it doesn't overflow when multiplied by itself
        if (sqrtRatioX96 <= type(uint128).max) {
            uint256 ratioX192 = uint256(sqrtRatioX96) * sqrtRatioX96;
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX192, baseAmount, 1 << 192)
                : FullMath.mulDiv(1 << 192, baseAmount, ratioX192);
        } else {
            uint256 ratioX128 = FullMath.mulDiv(sqrtRatioX96, sqrtRatioX96, 1 << 64);
            quoteAmount = baseToken < quoteToken
                ? FullMath.mulDiv(ratioX128, baseAmount, 1 << 128)
                : FullMath.mulDiv(1 << 128, baseAmount, ratioX128);
        }
    }
}
