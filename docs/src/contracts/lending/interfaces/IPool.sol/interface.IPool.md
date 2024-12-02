# IPool
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/interfaces/IPool.sol)


## Functions
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

### setExtraReward

*Sets the extra reward. Only the configurator can set it.*


```solidity
function setExtraReward(uint256 extraReward) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`extraReward`|`uint256`|fixed reward for extra liquidation.|


### setBorrowRate

The borrow rate is the annual interest rate that borrowers pay to lenders.
The function converts the borrow rate per year to a borrow rate per second.
The borrow rate is stored in `_borrowRatePerSec` and `_lastUpdateRate` is updated to the current block timestamp.

*Set the borrow rate of the contract. Only the configurator can set it.
The precision of the borrow rate is 18.
Example 5% = 5e18*


```solidity
function setBorrowRate(uint256 borrowRatePerYear) external;
```

### setHealthRewardConfig


```solidity
function setHealthRewardConfig(
    uint256 newMinHealthPercent,
    uint256 newLiquidateHealthPercent,
    uint128 newHealthPurpose,
    uint256 newRewardLiquidatorPercent,
    uint256 newRewardPlatformPercent
) external;
```

### setMinLoan


```solidity
function setMinLoan(uint256 newMinLoan) external;
```

### borrow

Creates a new position with the given `loan` and `collateral` amounts.


```solidity
function borrow(uint128 loan, uint128 collateral, uint256 posId) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loan`|`uint128`|The amount of the loan to be borrowed.|
|`collateral`|`uint128`|The amount of collateral to be put up as collateral.|
|`posId`|`uint256`|The ID of the new position.|


### borrowMore

Adds more loan and collateral to an existing position.
This function allows a user to add more loan and collateral to an existing position.


```solidity
function borrowMore(uint256 posId, uint128 collateral, uint128 loan) external returns (uint256 commissionQuote);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`posId`|`uint256`|The ID of the position to add more loan and collateral to.|
|`collateral`|`uint128`|The amount of collateral to add to the position.|
|`loan`|`uint128`|The amount of loan to add to the position.|


### repay

Repays a loan from a position.
This function allows a user to repay a loan from a position. If the `loanRepayment` is equal to the total loan amount of the position, the function deletes the position and returns the entire collateral as a refund. Otherwise, it decreases the loan amount by `loanRepayment` and increases the collateral by `refundCollateral`.


```solidity
function repay(uint128 loanRepayment, uint256 posId, uint128 refundCollateral)
    external
    returns (uint256, bool isClosePosition, uint256 commissionQuote);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loanRepayment`|`uint128`|The amount of loan to be repaid.|
|`posId`|`uint256`|The ID of the position to repay the loan from.|
|`refundCollateral`|`uint128`|The amount of collateral to be refunded.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|refundColl The amount of collateral refunded.|
|`isClosePosition`|`bool`|A boolean indicating whether the position was closed.|
|`commissionQuote`|`uint256`|The amount of commission charged.|


### liquidate

Liquidates the position with the given ID.
The function calculates the health factor of the position and checks if it is in the liquidation zone.
If it is, the function calculates the liquidation amount based on the health factor and the liquidation rate.
It then updates the position's loan, collateral, and K-value.


```solidity
function liquidate(uint256 posId)
    external
    returns (uint256 liqLoan, uint128 liqColl, uint256 rewPlatform, uint256 rewLiquidator, uint256 commissionQuote);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`posId`|`uint256`|The ID of the position to liquidate.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`liqLoan`|`uint256`|The amount of loan liquidated.|
|`liqColl`|`uint128`|The amount of collateral liquidated.|
|`rewPlatform`|`uint256`|The amount of platform reward.|
|`rewLiquidator`|`uint256`|The amount of liquidator reward.|
|`commissionQuote`|`uint256`|The amount of commission charged.|


### extraLiquidate

Extra liquidation of the position. This works if the operability of the position is below zero


```solidity
function extraLiquidate(uint256 posId)
    external
    returns (uint256 liqLoan, uint128 liqColl, uint256 extraReward, int256 loss);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`posId`|`uint256`|The ID of the position to be liquidated.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`liqLoan`|`uint256`|The total amount of loan to be liquidated.|
|`liqColl`|`uint128`|The total amount of collateral to be liquidated.|
|`extraReward`|`uint256`|The additional reward given to the liquidator for extra liquidation.|
|`loss`|`int256`|The loss incurred by the platform.|


### getCurrentK

Returns the current K value of the pool.


```solidity
function getCurrentK() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The current K value.|


### getHealthConfig

Returns the health configuration of the pool.


```solidity
function getHealthConfig()
    external
    view
    returns (int256 minHealthPercent, int256 liquidateHealthPercent, uint128 healthPurpose);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`minHealthPercent`|`int256`|The minimum health percentage.|
|`liquidateHealthPercent`|`int256`|The liquidation health percentage.|
|`healthPurpose`|`uint128`|The health purpose.|


### getRewardConfig

Returns the reward configuration of the pool.


```solidity
function getRewardConfig() external view returns (uint256 rewardLiquidatorPercent, uint256 rewardPlatformPercent);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardLiquidatorPercent`|`uint256`|The percentage of rewards for liquidators.|
|`rewardPlatformPercent`|`uint256`|The percentage of rewards for the platform.|


### getBorrowRateInfo

Returns the borrow rate information of the pool.


```solidity
function getBorrowRateInfo() external view returns (uint256 borrowRatePerSec, uint256 lastUpdateRate);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`borrowRatePerSec`|`uint256`|The borrow rate per second.|
|`lastUpdateRate`|`uint256`|The timestamp of the last borrow rate update.|


### getAcceptableTimeInterval

Returns the acceptable time interval of the chainlink


```solidity
function getAcceptableTimeInterval() external view returns (uint256);
```

### getInfoPosition

Returns the information of a position.
This function calculates the health factor of the position by calling `_calcHealth`.
It also calculates the base currency and quote currency commissions by calling `_calculateLoanFees`.
The function then returns the position details, health factor, and commissions.


```solidity
function getInfoPosition(uint256 posId)
    external
    view
    returns (Position memory position, int256 healthFactor, uint256 commissionBase, uint256 commissionQuote);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`posId`|`uint256`|The ID of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`position`|`Position`|The position details.|
|`healthFactor`|`int256`|The health factor of the position.|
|`commissionBase`|`uint256`|The base currency commission.|
|`commissionQuote`|`uint256`|The quote currency commission.|


### getTokens

Returns the token addresses of the pool.


```solidity
function getTokens() external view returns (address token0, address token1);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`address`|The address of the first token.|
|`token1`|`address`|The address of the second token.|


### getPositionHealth

Calculates the health factor of a position.


```solidity
function getPositionHealth(uint256 posId) external view returns (int256 healthFactor);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`posId`|`uint256`|The ID of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`healthFactor`|`int256`|The health factor of the position.|


## Events
### HealthRewardConfigUpdated

```solidity
event HealthRewardConfigUpdated(
    uint256 minHealthPercent,
    uint256 liquidateHealthPercent,
    uint128 healthPurpose,
    uint256 rewardLiquidatorPercent,
    uint256 rewardPlatformPercent
);
```

### BorrowRateUpdated

```solidity
event BorrowRateUpdated(uint256 borrowRatePerSec);
```

### ConfigUpdated

```solidity
event ConfigUpdated(address dataFeed, uint256 acceptableTimeInterval);
```

## Errors
### TooLowHealth

```solidity
error TooLowHealth(int256 health, int256 minHealth);
```

### PositionNotInLiquidationZone

```solidity
error PositionNotInLiquidationZone(int256 health, int256 liquidationMinHealth);
```

### PositionEmpty

```solidity
error PositionEmpty(uint256 id);
```

### OnlyAdapter

```solidity
error OnlyAdapter();
```

### OnlyConfigurator

```solidity
error OnlyConfigurator();
```

### OracleOldPrice

```solidity
error OracleOldPrice(uint256 updatedAt, uint256 time);
```

### InvalidRepayment

```solidity
error InvalidRepayment(uint128 loan, uint128 collateral);
```

### NotExtraLiquidate

```solidity
error NotExtraLiquidate(int256 healthFactor);
```

### PositionUnderwater

```solidity
error PositionUnderwater();
```

### PositionNotUnderwater

```solidity
error PositionNotUnderwater(int256 healthFactor);
```

### InvalidRewardConfig

```solidity
error InvalidRewardConfig();
```

### ZeroAddress

```solidity
error ZeroAddress();
```

### LoanLessThanMinLoan

```solidity
error LoanLessThanMinLoan(uint256 loan, uint256 _minLoan);
```

### InvalidHealthPurpose

```solidity
error InvalidHealthPurpose(uint256 sum);
```

## Structs
### Position

```solidity
struct Position {
    uint128 collateral;
    uint128 loan;
    uint256 k;
}
```

