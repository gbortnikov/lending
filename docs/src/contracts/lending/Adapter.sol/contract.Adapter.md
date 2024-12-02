# Adapter
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/Adapter.sol)

**Inherits:**
[IAdapter](/contracts/lending/interfaces/IAdapter.sol/interface.IAdapter.md), Initializable, PausableUpgradeable


## State Variables
### NATIVE

```solidity
address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


### _userCollateralByToken
*account => token => InfoCollateral*


```solidity
mapping(address => mapping(address => InfoCollateral)) private _userCollateralByToken;
```


### _positionInfoById
*idPos => InfoPosition*


```solidity
mapping(uint256 => InfoPosition) private _positionInfoById;
```


### counterId

```solidity
uint256 public counterId;
```


### _configurator

```solidity
IConfigurator internal _configurator;
```


### _treasure

```solidity
address payable internal _treasure;
```


### entryFee

```solidity
uint256 public entryFee;
```


## Functions
### onlyConfigurator


```solidity
modifier onlyConfigurator();
```

### initialize

*Initializes the Adapter contract.*


```solidity
function initialize(address addrConfigurator, address payable addrTreasure) external override initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`addrConfigurator`|`address`|The address of the Configurator contract.|
|`addrTreasure`|`address payable`|The address of the Treasure contract.|


### pause

Pauses the contract. Only the configurator can pause it.


```solidity
function pause() external override onlyConfigurator;
```

### unpause

Unpauses the contract. Only the configurator can unpause it.


```solidity
function unpause() external override onlyConfigurator;
```

### setEntryFee


```solidity
function setEntryFee(uint256 fee) external override onlyConfigurator;
```

### supply

Supplies collateral to the contract.

*This function can only be called when the contract is not paused.*


```solidity
function supply(address token, uint256 amount) external payable override whenNotPaused;
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
function withdrawCollateral(address token, uint256 amount) external override whenNotPaused;
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
function borrow(address token0, address token1, uint128 loan, uint128 provision)
    external
    payable
    override
    whenNotPaused;
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
function borrowMore(uint256 idPosition, uint128 addCollateral, uint128 addLoan) external override whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`idPosition`|`uint256`|The ID of the position to borrow from.|
|`addCollateral`|`uint128`|The amount of additional collateral to provide.|
|`addLoan`|`uint128`|The amount of additional USD3 tokens to borrow.|


### repay

Repay function allows a user to repay the loan.

*This function can only be called when the contract is not paused.
It checks the position status and validates the position.
It also calculates the refund collateral and commission quote.
If the position is closed, it updates the position status.
It updates the used collateral and collateral of the InfoCollateral struct.*


```solidity
function repay(uint256 idPosition, uint128 loanRepayment, uint128 refundCollateral)
    external
    payable
    override
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`idPosition`|`uint256`|ID of the position to repay|
|`loanRepayment`|`uint128`|the amount of loan to repay|
|`refundCollateral`|`uint128`|the amount of collateral to refund.|


### liquidate

*This function can only be called when the contract is not paused.
It liquidates the position specified by the `idPosition` parameter.
It checks if the position is open and if not, it reverts.
It calculates the liquidation loan, liquidation collateral, platform reward, liquidator reward, and commission quote.
It updates the used collateral and collateral of the InfoCollateral struct.*


```solidity
function liquidate(uint256 idPosition) external payable override whenNotPaused;
```

### extraLiquidate


```solidity
function extraLiquidate(uint256 idPosition) external override whenNotPaused;
```

### getInfoCollateral

This function allows to retrieve the collateral information and the available collateral amount for a given token and account.

*It returns an InfoCollateral struct and the available collateral amount for the given parameters.*


```solidity
function getInfoCollateral(address token, address account)
    external
    view
    override
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

This function returns the full information of a position, including the position's details,
health factor, base currency commission, and quote currency commission.

*It calls the `getInfoPosition` function of the `IPool` contract to retrieve the position details and the
health factor. It then retrieves the base currency and quote currency commissions.*


```solidity
function getFullInfoPosition(uint256 idPosition)
    external
    view
    override
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

*It retrieves the position's details from the `_positionInfoById` mapping.*


```solidity
function getInfoPosition(uint256 idPosition) external view override returns (InfoPosition memory infoPosition);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`idPosition`|`uint256`|The ID of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`infoPosition`|`InfoPosition`|The `InfoPosition` struct containing the position's details.|


### _calcAvailableCollateral

This internal function calculates the available collateral amount for a given `InfoCollateral` struct.

*It subtracts the `usedCollateral` from the `collateral` field of the `infoCollateral` parameter.*


```solidity
function _calcAvailableCollateral(InfoCollateral storage infoCollateral)
    internal
    view
    returns (uint256 availableCollateral);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`infoCollateral`|`InfoCollateral`|The `InfoCollateral` struct to calculate the available collateral for.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`availableCollateral`|`uint256`|The available collateral amount.|


### _validatePosition

This internal function validates a position by checking its details.

*It checks if the position's pool is not zero, if the position's status is OPEN,
and if the owner of the position is the caller.*


```solidity
function _validatePosition(InfoPosition storage infoPosition, uint256 idPosition) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`infoPosition`|`InfoPosition`|The `InfoPosition` struct to validate.|
|`idPosition`|`uint256`|The ID of the position.|


