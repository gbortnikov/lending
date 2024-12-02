# IStation
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/c7db5af1f45d7a5d76d56fec25448244aa8d00e7/contracts/IStation.sol)


## Functions
### initialize


```solidity
function initialize(address usd3, address eur3, uint256 minAmountUsd3, uint256 minAmountEur3, uint32 twapDuration)
    external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`usd3`|`address`|the address of the USD3 token contract|
|`eur3`|`address`||
|`minAmountUsd3`|`uint256`|the minimum amount of USD3 to be deposited when using the station|
|`minAmountEur3`|`uint256`||
|`twapDuration`|`uint32`||


### setFee

Sets the fee to be taken from users when they swap tokens using the station


```solidity
function setFee(uint256 fee) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint256`|The new fee to be taken from users when they swap tokens using the station|


### setMinAmounts

Sets the minimum amount of USD3 that must be provided when using the station


```solidity
function setMinAmounts(uint256 minAmountUsd3, uint256 minAmountEur3) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minAmountUsd3`|`uint256`|the new minimum amount of USD3 that must be provided when using the station|
|`minAmountEur3`|`uint256`||


### setTwapDuration

Sets the duration of the TWAP (Time Weighted Average Price) for a token

*This function can only be called by an admin and will update the duration of the TWAP for all tokens.*


```solidity
function setTwapDuration(uint32 twapDuration) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`twapDuration`|`uint32`|The new duration of the TWAP in seconds|


### includePoolToListUsd3

Adds a token to the list of supported tokens

*This function can only be called by an admin and will fail if the token or pool is the zero address.*


```solidity
function includePoolToListUsd3(address token, address pool) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|the address of the token to be added to the list|
|`pool`|`address`|the address of the Uniswap V3 pool for the token|


### includePoolToListEur3

Adds a token to the list of supported tokens

*This function can only be called by an admin and will fail if the token or pool is the zero address.*


```solidity
function includePoolToListEur3(address token, address pool) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|the address of the token to be added to the list|
|`pool`|`address`|the address of the Uniswap V3 pool for the token|


### excludePoolToListUSD3

Removes a token from the list of supported tokens

*This function can only be called by an admin and will fail if the token is the zero address.
When a token is removed from the list, it is deleted from the mapping and no longer accepted by the station.*


```solidity
function excludePoolToListUSD3(address token) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|the address of the token to be removed from the list|


### excludePoolToListEur3


```solidity
function excludePoolToListEur3(address token) external;
```

### deposit

Deposits a given amount of a given token into the station

*This function can only be called by an admin and will fail if the token or amount is zero.*


```solidity
function deposit(address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|the address of the token to be deposited|
|`amount`|`uint256`|the amount of the token to be deposited|


### withdraw

Withdraws a given amount of a given token from the station

*This function can only be called by an admin and will fail if the token, amount, or recipient is zero.*


```solidity
function withdraw(address token, uint256 amount, address to) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to be withdrawn|
|`amount`|`uint256`|The amount of the token to be withdrawn|
|`to`|`address`|The address that will receive the withdrawn tokens|


### pause

Pauses the station

*This function can only be called by an admin and will fail if the station is already paused.*


```solidity
function pause() external;
```

### unpause

Unpauses the station

*This function can only be called by an admin and will fail if the station is already unpaused.*


```solidity
function unpause() external;
```

### swapUSD3

Exchanges a specified number of tokens. the base or quote token must be USD3


```solidity
function swapUSD3(address base, address quote, uint256 amountIn) external returns (uint256 amountOut, uint256 tax);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`base`|`address`|The token being swapped in|
|`quote`|`address`|The token being swapped out|
|`amountIn`|`uint256`|The amount of the token being swapped in|


### swapEUR3

Exchanges a specified number of tokens. the base or quote token must be EUR3


```solidity
function swapEUR3(address base, address quote, uint256 amountIn) external returns (uint256 amountOut, uint256 tax);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`base`|`address`|The token being swapped in|
|`quote`|`address`|The token being swapped out|
|`amountIn`|`uint256`|The amount of the token being swapped in|


### getMinAmounts

Returns the minimum amounts that must be swapped for each currency.


```solidity
function getMinAmounts() external view returns (uint256, uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|minAmountUsd3 The minimum amount that must be swapped for USD3.|
|`<none>`|`uint256`|minAmountEur3 The minimum amount that must be swapped for EUR3.|


### getInfoPoolForUSD3

Returns the available balance of the token in the Station's contract and the address of the pool used for
swapping, given the token is used for swapping with USD3.


```solidity
function getInfoPoolForUSD3(address token) external view returns (uint256 availableAmount, address pool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to get the information for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`availableAmount`|`uint256`|The available balance of the token in the Station's contract.|
|`pool`|`address`|The address of the pool used for swapping.|


### getInfoPoolForEUR3

Returns the available balance of the token in the Station's contract and the address of the pool used for
swapping, given the token is used for swapping with EUR3.


```solidity
function getInfoPoolForEUR3(address token) external view returns (uint256 availableAmount, address pool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to get the information for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`availableAmount`|`uint256`|The available balance of the token in the Station's contract.|
|`pool`|`address`|The address of the pool used for swapping.|


### getTwapDuration

Returns the duration of the TWAP (Time Weighted Average Price) for all tokens.

*This function can be used to know which TWAP duration is being used to calculate the prices.*


```solidity
function getTwapDuration() external view returns (uint256 twap);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`twap`|`uint256`|The duration of the TWAP in seconds.|


### calculatedAmountOut

Gets a twap for the pool, and calculates the amount out for this twap according to the specified amount


```solidity
function calculatedAmountOut(address pool, uint256 baseAmount, address baseToken, address quoteToken)
    external
    view
    returns (uint256 amountOut);
```

## Events
### PoolUsd3Updated
*Emitted when the address of the Uniswap V3 pool for USD3 is updated.*


```solidity
event PoolUsd3Updated(address indexed token, address pool);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token (e.g. WUSD3).|
|`pool`|`address`|The address of the Uniswap V3 pool for USD3.|

### PoolEur3Updated
*Emitted when the address of the Uniswap V3 pool for EUR3 is updated.*


```solidity
event PoolEur3Updated(address indexed token, address pool);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token (e.g. WEUR3).|
|`pool`|`address`|The address of the Uniswap V3 pool for EUR3.|

### Deposit
*Emitted when a deposit is made into the Station.*


```solidity
event Deposit(address indexed token, uint256 amount);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token being deposited.|
|`amount`|`uint256`|The amount of tokens being deposited.|

### Withdraw
*Emitted when a withdrawal is made from the Station.*


```solidity
event Withdraw(address indexed token, uint256 amount, address indexed to);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token being withdrawn.|
|`amount`|`uint256`|The amount of tokens being withdrawn.|
|`to`|`address`|The address receiving the withdrawn tokens.|

### Swap
*Emitted when a swap is executed.*


```solidity
event Swap(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut, uint256 tax);
```

**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenIn`|`address`|The address of the token that is being swapped in.|
|`tokenOut`|`address`|The address of the token that is being swapped out.|
|`amountIn`|`uint256`|The amount of `tokenIn` that is being swapped.|
|`amountOut`|`uint256`|The number of "tokenOut" received as a result of the exchange.|
|`tax`|`uint256`|The amount of `tokenOut` that is being taken as a tax.|

### UpdatedMinAmount

```solidity
event UpdatedMinAmount(uint256 minAmountUsd3, uint256 minAmountEur3);
```

### UpdatedTwapDuration

```solidity
event UpdatedTwapDuration(uint32 twapDuration);
```

## Errors
### ZeroAddress

```solidity
error ZeroAddress();
```

### AmountMustBeMore

```solidity
error AmountMustBeMore(uint256 amount, uint256 minAmount);
```

### TokenIsNotInList

```solidity
error TokenIsNotInList(address token);
```

### UserIsBanned

```solidity
error UserIsBanned();
```

### InvalidPool

```solidity
error InvalidPool();
```

### BadTokens

```solidity
error BadTokens(address base, address quote);
```

