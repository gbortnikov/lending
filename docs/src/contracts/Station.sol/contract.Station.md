# Station
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/c7db5af1f45d7a5d76d56fec25448244aa8d00e7/contracts/Station.sol)

**Inherits:**
[IStation](/contracts/IStation.sol/interface.IStation.md), AccessControlUpgradeable, [ExtensionFee](/contracts/extensions/ExtensionFee.sol/abstract.ExtensionFee.md), [ExtensionWhiteList](/contracts/extensions/ExtensionWhiteList.sol/abstract.ExtensionWhiteList.md), UUPSUpgradeable, PausableUpgradeable


## State Variables
### ADMIN_ROLE
The public identifier for Admin Role


```solidity
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
```


### UPGRADER_ROLE

```solidity
bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
```


### USD3

```solidity
address public USD3;
```


### EUR3

```solidity
address public EUR3;
```


### _minAmountUsd3

```solidity
uint256 internal _minAmountUsd3;
```


### _minAmountEur3

```solidity
uint256 internal _minAmountEur3;
```


### _twapDuration

```solidity
uint32 internal _twapDuration;
```


### __gap

```solidity
uint256[10] private __gap;
```


### _poolWithUSD3

```solidity
mapping(address => address) internal _poolWithUSD3;
```


### _poolWithEUR3

```solidity
mapping(address => address) internal _poolWithEUR3;
```


## Functions
### isZeroAddress


```solidity
modifier isZeroAddress(address token);
```

### validatePool


```solidity
modifier validatePool(address token, address pool, address tokenBase);
```

### initialize


```solidity
function initialize(address usd3, address eur3, uint256 minAmountUsd3, uint256 minAmountEur3, uint32 twapDuration)
    external
    override
    initializer;
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
function setFee(uint256 fee) external override onlyRole(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`fee`|`uint256`|The new fee to be taken from users when they swap tokens using the station|


### setUserStatus

Sets the status of a user


```solidity
function setUserStatus(address account, UserStatus status) external onlyRole(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|The address of the user whose status is to be set|
|`status`|`UserStatus`|The new status of the user, which can be one of NORMAL, BANNED, or PRIVILEGED|


### setMinAmounts

Sets the minimum amount of USD3 and EUR3 that can be swapped using the station

*This function can only be called by an admin and will update the minimum amounts for all tokens.
The minimum amounts are used to prevent users from swapping very small amounts,
which can lead to issues with pricing and liquidity.*


```solidity
function setMinAmounts(uint256 minAmountUsd3, uint256 minAmountEur3) external override onlyRole(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`minAmountUsd3`|`uint256`|The new minimum amount of USD3 that can be swapped|
|`minAmountEur3`|`uint256`|The new minimum amount of EUR3 that can be swapped|


### setTwapDuration

Sets the duration of the TWAP (Time Weighted Average Price) for a token

*This function can only be called by an admin and will update the duration of the TWAP for all tokens.*


```solidity
function setTwapDuration(uint32 twapDuration) external override onlyRole(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`twapDuration`|`uint32`|The new duration of the TWAP in seconds|


### includePoolToListUsd3

Adds a token to the list of supported tokens

*This function can only be called by an admin and will fail if the token or pool is the zero address.*


```solidity
function includePoolToListUsd3(address token, address pool)
    external
    override
    onlyRole(ADMIN_ROLE)
    validatePool(token, pool, USD3);
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
function includePoolToListEur3(address token, address pool)
    external
    override
    onlyRole(ADMIN_ROLE)
    validatePool(token, pool, EUR3);
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
function excludePoolToListUSD3(address token) external override onlyRole(ADMIN_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|the address of the token to be removed from the list|


### excludePoolToListEur3


```solidity
function excludePoolToListEur3(address token) external override onlyRole(ADMIN_ROLE);
```

### deposit

Deposits a given amount of a given token into the station

*This function can only be called by an admin and will fail if the token or amount is zero.*


```solidity
function deposit(address token, uint256 amount) external override onlyRole(ADMIN_ROLE) isZeroAddress(token);
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
function withdraw(address token, uint256 amount, address to) external override onlyRole(ADMIN_ROLE);
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
function pause() external override onlyRole(ADMIN_ROLE);
```

### unpause

Unpauses the station

*This function can only be called by an admin and will fail if the station is already unpaused.*


```solidity
function unpause() external override onlyRole(ADMIN_ROLE);
```

### swapUSD3

Exchanges a specified number of tokens. the base or quote token must be USD3


```solidity
function swapUSD3(address base, address quote, uint256 amountIn)
    external
    override
    whenNotPaused
    returns (uint256 amountOutWithoutFee, uint256 tax);
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
function swapEUR3(address base, address quote, uint256 amountIn)
    external
    override
    whenNotPaused
    returns (uint256 amountOutWithoutFee, uint256 tax);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`base`|`address`|The token being swapped in|
|`quote`|`address`|The token being swapped out|
|`amountIn`|`uint256`|The amount of the token being swapped in|


### getInfoPoolForUSD3

Returns the available balance of the token in the Station's contract and the address of the pool used for
swapping, given the token is used for swapping with USD3.


```solidity
function getInfoPoolForUSD3(address token) external view override returns (uint256 availableAmount, address pool);
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
function getInfoPoolForEUR3(address token) external view override returns (uint256 availableAmount, address pool);
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


### getMinAmounts

Returns the minimum amounts that must be swapped for each currency.


```solidity
function getMinAmounts() external view override returns (uint256, uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|minAmountUsd3 The minimum amount that must be swapped for USD3.|
|`<none>`|`uint256`|minAmountEur3 The minimum amount that must be swapped for EUR3.|


### getTwapDuration

Returns the duration of the TWAP (Time Weighted Average Price) for all tokens.

*This function can be used to know which TWAP duration is being used to calculate the prices.*


```solidity
function getTwapDuration() external view override returns (uint256 twap);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`twap`|`uint256`|The duration of the TWAP in seconds.|


### calculatedAmountOut

Gets a twap for the pool, and calculates the amount out for this twap according to the specified amount


```solidity
function calculatedAmountOut(address pool, uint256 baseAmount, address baseToken, address quoteToken)
    public
    view
    override
    returns (uint256 amountOut);
```

### _exchange

The function first validates the user and token before performing the swap.
It then applies a fee to the swap depending on the user's status.
If the user is normal, the fee is taken from the amount out and the remaining amount is transferred to the user.
If the user is banned, the function throws a UserIsBanned exception.

*Performs a swap between two tokens.*


```solidity
function _exchange(address base, address quote, uint256 amountIn, uint256 amountOut)
    internal
    returns (uint256, uint256 tax);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`base`|`address`|The address of the base token.|
|`quote`|`address`|The address of the quote token.|
|`amountIn`|`uint256`|The amount of the base token to be swapped.|
|`amountOut`|`uint256`|The amount of the quote token to be received.|


### _authorizeUpgrade

*Authorizes the upgrade of the Station contract to a new implementation.
This function can only be called by an admin.*


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newImplementation`|`address`|The address of the new implementation of the Station contract.|


### _validateUsdPool

This function throws a TokenIsNotInList exception if the token is not in the list.
The list of supported tokens for USD3 can be updated by calling the includePoolToListUsd3 function.

*Validates whether a token is in the list of supported tokens for USD3.*


```solidity
function _validateUsdPool(address token) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to be validated.|


### _validateEurPool

This function throws a TokenIsNotInList exception if the token is not in the list.
The list of supported tokens for EUR3 can be updated by calling the includePoolToListEur3 function.

*Validates whether a token is in the list of supported tokens for EUR3.*


```solidity
function _validateEurPool(address token) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to be validated.|


