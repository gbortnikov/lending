# Treasure
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/Treasure.sol)

**Inherits:**
[ITreasure](/contracts/lending/interfaces/ITreasure.sol/interface.ITreasure.md), Initializable


## State Variables
### _configurator

```solidity
address internal _configurator;
```


### _adapter

```solidity
address internal _adapter;
```


### _tokenTaxLiquidate

```solidity
mapping(address => uint256) internal _tokenTaxLiquidate;
```


### _tokenTaxBorrow

```solidity
mapping(address => uint256) internal _tokenTaxBorrow;
```


### _tokenLoss

```solidity
mapping(address => int256) internal _tokenLoss;
```


### _tokenTotalSupply

```solidity
mapping(address => uint256) internal _tokenTotalSupply;
```


### _tokenLiquidatedCollateral

```solidity
mapping(address => uint256) internal _tokenLiquidatedCollateral;
```


## Functions
### onlyConfigurator


```solidity
modifier onlyConfigurator();
```

### onlyAdapter


```solidity
modifier onlyAdapter();
```

### initialize


```solidity
function initialize(address configurator, address adapter) external override initializer;
```

### receive


```solidity
receive() external payable override;
```

### replenishLosses

*This function allows the configurator to replenish the losses for a given token.
It adds the specified amount to the total losses of the token.*


```solidity
function replenishLosses(address token, uint256 amount) external override onlyConfigurator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token for which the losses are being replenished.|
|`amount`|`uint256`|The amount of losses to replenish.|


### transferTo

*Transfers tokens from the treasury to another address.
Only the adapter can call this function*


```solidity
function transferTo(address token, address to, uint256 amount) external override onlyAdapter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to transfer.|
|`to`|`address`|The address to transfer the tokens to.|
|`amount`|`uint256`|The amount of tokens to transfer.|


### withdrawTaxLiquidate

*Withdraws liquidate tax from the treasury.
Only the configurator can call this function*


```solidity
function withdrawTaxLiquidate(address token, address to, uint256 amount) external override onlyConfigurator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to withdraw the tax from.|
|`to`|`address`|The address to transfer the tax to.|
|`amount`|`uint256`|The amount of tax to withdraw.|


### withdrawTaxBorrow

*Withdraws borrowing tax from the treasury.
Only the configurator can call this function.*


```solidity
function withdrawTaxBorrow(address token, address to, uint256 amount) external override onlyConfigurator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to withdraw the tax from.|
|`to`|`address`|The address to transfer the tax to.|
|`amount`|`uint256`|The amount of tax to withdraw.|


### withdrawLiquidateCollateral


```solidity
function withdrawLiquidateCollateral(address token, address to, uint256 amount) external override onlyConfigurator;
```

### refund

*Deposits tokens into the treasury.
Only the configurator can call this function.*


```solidity
function refund(address token, address account, uint256 amount) external override onlyConfigurator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to deposit.|
|`account`|`address`||
|`amount`|`uint256`|The amount of tokens to deposit.|


### investCollateral

*Withdraws tokens from the treasury.
Only the configurator can call this function.*


```solidity
function investCollateral(address token, address to, uint256 amount) external override onlyConfigurator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to withdraw.|
|`to`|`address`|The address to transfer the tokens to.|
|`amount`|`uint256`|The amount of tokens to withdraw.|


### addTax

*Adds taxes for liquidation and borrowing for a given token.
Only the adapter can call this function*


```solidity
function addTax(address token, uint256 taxLiquidate, uint256 taxBorrow) external override onlyAdapter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to add taxes for.|
|`taxLiquidate`|`uint256`|The amount of tax to add for liquidation.|
|`taxBorrow`|`uint256`|The amount of tax to add for borrowing.|


### addLoss

*Adds a loss to the treasury for a given token.
Only the adapter can call this function.*


```solidity
function addLoss(address token, int256 loss) external override onlyAdapter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to add loss for.|
|`loss`|`int256`|The amount of loss to add.|


### addCollateral


```solidity
function addCollateral(address token, uint256 amount) external onlyAdapter;
```

### subCollateral


```solidity
function subCollateral(address token, uint256 amount) external onlyAdapter;
```

### addLiquidateCollateral


```solidity
function addLiquidateCollateral(address token, uint256 amount) public override onlyAdapter;
```

### getTax

*Returns the liquidate and borrow taxes for a given token.*


```solidity
function getTax(address token) external view override returns (uint256 taxLiquidate, uint256 taxBorrow);
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
function balanceOf(address token) external view override returns (uint256);
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
function getAddresses() external view override returns (address, address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|configurator The address of the configurator.|
|`<none>`|`address`|adapter The address of the adapter.|


### _addTaxLiquidate

*Adds the liquidate tax for a given token.*


```solidity
function _addTaxLiquidate(address token, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to add the tax for.|
|`amount`|`uint256`|The amount of tax to add.|


### _addTaxBorrow

*Adds the borrow tax for a given token.*


```solidity
function _addTaxBorrow(address token, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The token to add the tax for.|
|`amount`|`uint256`|The amount of tax to add.|


