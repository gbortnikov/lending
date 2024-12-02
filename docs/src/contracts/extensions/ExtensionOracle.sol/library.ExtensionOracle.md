# ExtensionOracle
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/c7db5af1f45d7a5d76d56fec25448244aa8d00e7/contracts/extensions/ExtensionOracle.sol)


## Functions
### _getTwap

*Returns the TWAP (Time Weighted Average Price) of a pool for the given twapDuration*


```solidity
function _getTwap(address pool, uint32 twapDuration) internal view returns (int24 twap);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`pool`|`address`|The address of the Uniswap V3 pool|
|`twapDuration`|`uint32`|The duration of the time window for which the TWAP is calculated, in seconds|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`twap`|`int24`|The TWAP of the pool, as a 24-bit integer|


### _getQuoteAtTick


```solidity
function _getQuoteAtTick(int24 tick, uint128 baseAmount, address baseToken, address quoteToken)
    internal
    pure
    returns (uint256 quoteAmount);
```

