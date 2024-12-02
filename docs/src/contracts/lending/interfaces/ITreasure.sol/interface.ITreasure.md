# ITreasure
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/interfaces/ITreasure.sol)


## Functions
### receive


```solidity
receive() external payable;
```

### initialize


```solidity
function initialize(address configurator, address adapter) external;
```

### addTax

*Adds taxes for liquidation and borrowing for a given token.*


```solidity
function addTax(address token, uint256 taxLiquidate, uint256 taxBorrow) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to add taxes for.|
|`taxLiquidate`|`uint256`|The amount of tax to add for liquidation.|
|`taxBorrow`|`uint256`|The amount of tax to add for borrowing.|


### addLoss


```solidity
function addLoss(address token, int256 loss) external;
```

### addCollateral


```solidity
function addCollateral(address token, uint256 amount) external;
```

### subCollateral


```solidity
function subCollateral(address token, uint256 amount) external;
```

### addLiquidateCollateral


```solidity
function addLiquidateCollateral(address token, uint256 amount) external;
```

### replenishLosses


```solidity
function replenishLosses(address token, uint256 amount) external;
```

### transferTo

*Transfers tokens from the treasury to another address.*


```solidity
function transferTo(address token, address to, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to transfer.|
|`to`|`address`|The address to transfer the tokens to.|
|`amount`|`uint256`|The amount of tokens to transfer.|


### withdrawTaxLiquidate

*Withdraws liquidate tax from the treasury.*


```solidity
function withdrawTaxLiquidate(address token, address to, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to withdraw the tax from.|
|`to`|`address`|The address to transfer the tax to.|
|`amount`|`uint256`|The amount of tax to withdraw.|


### withdrawTaxBorrow

*Withdraws borrowing tax from the treasury.*


```solidity
function withdrawTaxBorrow(address token, address to, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to withdraw the tax from.|
|`to`|`address`|The address to transfer the tax to.|
|`amount`|`uint256`|The amount of tax to withdraw.|


### withdrawLiquidateCollateral


```solidity
function withdrawLiquidateCollateral(address token, address to, uint256 amount) external;
```

### refund

*Deposits tokens into the treasury.*


```solidity
function refund(address token, address account, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to deposit.|
|`account`|`address`||
|`amount`|`uint256`|The amount of tokens to deposit.|


### investCollateral

*Withdraws tokens from the treasury.*


```solidity
function investCollateral(address token, address to, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to withdraw.|
|`to`|`address`|The address to transfer the tokens to.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### getTax

*Returns the liquidate and borrow taxes for a given token.*


```solidity
function getTax(address token) external view returns (uint256 taxLiquidate, uint256 taxBorrow);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to get the taxes for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`taxLiquidate`|`uint256`|The liquidate tax for the token.|
|`taxBorrow`|`uint256`|The borrow tax for the token.|


### balanceOf

*Returns the balance of a given token in the treasury.*


```solidity
function balanceOf(address token) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to get the balance of.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The balance of the token in the treasury.|


### getAddresses

*Returns the addresses of the configurator and adapter.*


```solidity
function getAddresses() external view returns (address, address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|configurator The address of the configurator.|
|`<none>`|`address`|adapter The address of the adapter.|


## Events
### AddTax

```solidity
event AddTax(address indexed token, uint256 taxLiquidate, uint256 taxBorrow);
```

### Withdraw

```solidity
event Withdraw(address indexed token, address indexed account, uint256 amount);
```

### Refund

```solidity
event Refund(address token, address account, uint256 amount);
```

### WithdrawTaxLiquidate

```solidity
event WithdrawTaxLiquidate(address indexed token, address indexed account, uint256 amount);
```

### WithdrawTaxBorrow

```solidity
event WithdrawTaxBorrow(address indexed token, address indexed account, uint256 amount);
```

### WithdrawLiquidateCollateral

```solidity
event WithdrawLiquidateCollateral(address indexed token, address indexed account, uint256 amount);
```

### AddLoss

```solidity
event AddLoss(address indexed token, int256 loss);
```

### ReplenishLosses

```solidity
event ReplenishLosses(address token, uint256 amount);
```

## Errors
### OnlyConfigurator

```solidity
error OnlyConfigurator();
```

### OnlyAdapter

```solidity
error OnlyAdapter();
```

### ZeroAddress

```solidity
error ZeroAddress();
```

