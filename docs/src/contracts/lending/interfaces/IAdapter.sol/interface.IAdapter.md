# IAdapter
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/interfaces/IAdapter.sol)


## Functions
### initialize

*Initializes the Adapter contract.*


```solidity
function initialize(address addrConfigurator, address payable addrTreasure) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`addrConfigurator`|`address`|The address of the Configurator contract.|
|`addrTreasure`|`address payable`|The address of the Treasure contract.|


### pause

Pauses the contract. Only the configurator can pause it.


```solidity
function pause() external;
```

### unpause

Unpauses the contract. Only the configurator can unpause it.


```solidity
function unpause() external;
```

### setEntryFee


```solidity
function setEntryFee(uint256 fee) external;
```

### supply

Supplies collateral to the contract.

*This function can only be called when the contract is not paused.*


```solidity
function supply(address token, uint256 amount) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the collateral token.|
|`amount`|`uint256`|The amount of collateral to supply.|


### withdrawCollateral

Withdraws collateral from the contract.

*This function can only be called when the contract is not paused.*


```solidity
function withdrawCollateral(address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the collateral token.|
|`amount`|`uint256`|The amount of collateral to withdraw.|


### borrow

Allows a user to borrow a certain amount of USD3 tokens by providing collateral.

*This function can only be called when the contract is not paused.*


```solidity
function borrow(address token0, address token1, uint128 loan, uint128 provision) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`address`|The address of the first collateral token.|
|`token1`|`address`|The address of the second collateral token.|
|`loan`|`uint128`|The amount of USD3 tokens to borrow.|
|`provision`|`uint128`|The amount of collateral to provide.|


### borrowMore

Allows a user to borrow more USD3 tokens by providing additional collateral.

*This function can only be called when the contract is not paused.*


```solidity
function borrowMore(uint256 idPosition, uint128 addCollateral, uint128 addLoan) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`idPosition`|`uint256`|The ID of the position to borrow from.|
|`addCollateral`|`uint128`|The amount of additional collateral to provide.|
|`addLoan`|`uint128`|The amount of additional USD3 tokens to borrow.|


### repay

Repay function allows a user to repay the loan.

*This function can only be called when the contract is not paused.*


```solidity
function repay(uint256 idPosition, uint128 loanRepayment, uint128 refundCollateral) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`idPosition`|`uint256`|ID of the position to repay|
|`loanRepayment`|`uint128`|the amount of loan to repay|
|`refundCollateral`|`uint128`|the amount of collateral to refund.|


### liquidate

*This function can only be called when the contract is not paused.
It liquidates the position specified by the `idPosition` parameter.*


```solidity
function liquidate(uint256 idPosition) external payable;
```

### extraLiquidate


```solidity
function extraLiquidate(uint256 idPosition) external;
```

### getInfoCollateral

This function allows to retrieve the collateral information and the available collateral amount for a given token and account.

*It returns an InfoCollateral struct and the available collateral amount for the given parameters.*


```solidity
function getInfoCollateral(address token, address account)
    external
    view
    returns (InfoCollateral memory, uint256 availableCollateral);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the collateral token.|
|`account`|`address`|The address of the account.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`InfoCollateral`|infoCollateral The InfoCollateral struct containing the collateral information.|
|`availableCollateral`|`uint256`|The available collateral amount for the given token and account.|


### getFullInfoPosition

This function returns the full information of a position, including the position's details, health factor,
base currency commission, and quote currency commission.


```solidity
function getFullInfoPosition(uint256 idPosition)
    external
    view
    returns (
        InfoPosition memory infoPosition,
        IPool.Position memory position,
        int256 health,
        uint256 commissionBase,
        uint256 commissionQuote
    );
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`idPosition`|`uint256`|The ID of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`infoPosition`|`InfoPosition`|The `InfoPosition` struct containing the position's details.|
|`position`|`IPool.Position`|The `Position` struct containing the position's details.|
|`health`|`int256`|The health factor of the position.|
|`commissionBase`|`uint256`|The base currency commission.|
|`commissionQuote`|`uint256`|The quote currency commission.|


### getInfoPosition

This function returns information about collateral of a position.


```solidity
function getInfoPosition(uint256 idPosition) external view returns (InfoPosition memory infoPosition);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`idPosition`|`uint256`|The ID of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`infoPosition`|`InfoPosition`|The `InfoPosition` struct containing the position's details.|


### entryFee


```solidity
function entryFee() external view returns (uint256);
```

## Events
### Supply

```solidity
event Supply(address account, address token, uint256 amount, uint256 tax);
```

### WithdrawCollateral

```solidity
event WithdrawCollateral(address account, address token, uint256 amount);
```

### Borrow

```solidity
event Borrow(uint256 positionId, address pool, uint256 loan, uint256 provision);
```

### BorrowMore

```solidity
event BorrowMore(uint256 positionId, address pool, uint256 addCollateral, uint256 addLoan);
```

### Repay

```solidity
event Repay(uint256 positionId, uint256 loanRepayment, uint256 refundCollateral, PositionStatus statusPosition);
```

### Liquidate

```solidity
event Liquidate(
    uint256 positionId, uint256 liqLoan, uint256 liqColl, address pool, uint256 rewardLiquidator, uint256 rewardPlatform
);
```

### ExtraLiquidate

```solidity
event ExtraLiquidate(
    uint256 positionId, uint256 liqLoan, uint256 liqColl, address pool, uint256 rewardLiquidator, int256 loss
);
```

## Errors
### OnlyConfigurator

```solidity
error OnlyConfigurator();
```

### InsufficientCollateral

```solidity
error InsufficientCollateral(uint256 availableCollateral);
```

### InvalidToken

```solidity
error InvalidToken();
```

### InvalidPool

```solidity
error InvalidPool();
```

### OnlyPool

```solidity
error OnlyPool();
```

### OnlyOwnerPosition

```solidity
error OnlyOwnerPosition(address account);
```

### NotOpenPosition

```solidity
error NotOpenPosition(uint256 idPosition);
```

### ZeroAddress

```solidity
error ZeroAddress();
```

## Structs
### InfoCollateral

```solidity
struct InfoCollateral {
    uint256 collateral;
    uint256 usedCollateral;
}
```

### InfoPosition

```solidity
struct InfoPosition {
    address pool;
    address account;
    PositionStatus status;
}
```

## Enums
### PositionStatus

```solidity
enum PositionStatus {
    NOT_CREATED,
    OPEN,
    CLOSED
}
```

