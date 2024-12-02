# Pool
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/Pool.sol)

**Inherits:**
[IPoolUsd3](/contracts/lending/interfaces/IPoolUsd3.sol/interface.IPoolUsd3.md), Initializable, PausableUpgradeable


## State Variables
### PRECISION

```solidity
uint256 public constant PRECISION = 1e18;
```


### NATIVE

```solidity
address public constant NATIVE = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
```


### adapter
The address of the adapter contract that interacts with the pool.


```solidity
address public adapter;
```


### configurator
The address of the configurator contract that sets the configuration of the pool.


```solidity
address public configurator;
```


### dataFeed
The address of the data feed used to get the price of the token.


```solidity
AggregatorV3Interface public dataFeed;
```


### _token0
The address of the token0 used in the pool.


```solidity
address internal _token0;
```


### _token1
The address of the token1 used in the pool.


```solidity
address internal _token1;
```


### _healthPurpose
the health factor that should be after liquidation


```solidity
uint128 internal _healthPurpose;
```


### _dataFeedDecimals
The number of decimals of the data feed.


```solidity
uint256 internal _dataFeedDecimals;
```


### _decimalsToken0
The number of decimals of token0.


```solidity
uint256 internal _decimalsToken0;
```


### _decimalsToken1
The number of decimals of token1.


```solidity
uint256 internal _decimalsToken1;
```


### _acceptableTimeInterval
The acceptable time interval to update the borrow rate.


```solidity
uint256 internal _acceptableTimeInterval;
```


### _rewardLiquidatorPercent
The percentage of the reward for liquidation given to the liquidator.


```solidity
uint256 internal _rewardLiquidatorPercent;
```


### _rewardPlatformPercent
The percentage of the reward for liquidation given to the platform.


```solidity
uint256 internal _rewardPlatformPercent;
```


### _borrowRatePerSec
The borrow rate per second.


```solidity
uint256 internal _borrowRatePerSec;
```


### _lastUpdateRate
The timestamp of the last update of the borrow rate.


```solidity
uint256 internal _lastUpdateRate;
```


### _k
stores the last value of K that was at the time of the change the loan fee


```solidity
uint256 internal _k;
```


### _extraReward
The fixed reward for extra liquidation.


```solidity
uint256 internal _extraReward;
```


### _minHealthPercent
The minimum health factor for opening a position


```solidity
int256 internal _minHealthPercent;
```


### _liquidateHealthPercent
The health percentage threshold for liquidation.


```solidity
int256 internal _liquidateHealthPercent;
```


### _minLoan

```solidity
uint256 internal _minLoan;
```


### _positionById
The mapping that stores the positions of the lending pool. ID => Position


```solidity
mapping(uint256 => Position) internal _positionById;
```


## Functions
### onlyAdapter


```solidity
modifier onlyAdapter();
```

### onlyConfigurator


```solidity
modifier onlyConfigurator();
```

### initialize

Initialize the contract with the initial values of the variables.
This function is called during the contract deployment.


```solidity
function initialize(
    address token0,
    address token1,
    address chainlinkAggregator,
    address addrAdapter,
    address addrConfigurator
) external override initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`address`||
|`token1`|`address`||
|`chainlinkAggregator`|`address`||
|`addrAdapter`|`address`||
|`addrConfigurator`|`address`||


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

### setConfig

*Sets the configuration of the contract.
It allows the configurator to update the address of the Chainlink aggregator contract and the acceptable time interval.*


```solidity
function setConfig(address newDataFeed, uint256 newAcceptableTimeInterval) external override onlyConfigurator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newDataFeed`|`address`|The new address of the Chainlink aggregator contract.|
|`newAcceptableTimeInterval`|`uint256`|The new acceptable time interval.|


### setExtraReward

*Sets the extra reward. Only the configurator can set it.*


```solidity
function setExtraReward(uint256 extraReward) external override onlyConfigurator;
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
function setBorrowRate(uint256 borrowRatePerYear) external override onlyConfigurator;
```

### setHealthRewardConfig

*Sets the health configuration of the contract.
This function allows the configurator to update the minimum health percentage, liquidation health percentage, and health purpose.
Sum of the `newHealthPurpose`, `rewardLiquidatorPercent`, `rewardPlatformPercent` percentages must be less than or equal 10000.
The precision of the all percentages is 2.
Example 5% = 5e2*


```solidity
function setHealthRewardConfig(
    uint256 newMinHealthPercent,
    uint256 newLiquidateHealthPercent,
    uint128 newHealthPurpose,
    uint256 newRewardLiquidatorPercent,
    uint256 newRewardPlatformPercent
) external onlyConfigurator;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMinHealthPercent`|`uint256`|The new minimum health percentage.|
|`newLiquidateHealthPercent`|`uint256`|The new liquidation health percentage.|
|`newHealthPurpose`|`uint128`|The new health purpose. The function updates the `_minHealthPercent`, `_liquidateHealthPercent`, and `_healthPurpose` variables with the new values. It then emits a `HealthConfigUpdated` event with the new health configuration.|
|`newRewardLiquidatorPercent`|`uint256`||
|`newRewardPlatformPercent`|`uint256`||


### setMinLoan


```solidity
function setMinLoan(uint256 newMinLoan) external override onlyConfigurator;
```

### borrow

Creates a new position with the given `loan` and `collateral` amounts.


```solidity
function borrow(uint128 loan, uint128 collateral, uint256 posId) external override onlyAdapter whenNotPaused;
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
function borrowMore(uint256 posId, uint128 collateral, uint128 loan)
    external
    override
    onlyAdapter
    whenNotPaused
    returns (uint256 commissionQuote);
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
    override
    onlyAdapter
    whenNotPaused
    returns (uint256 refundColl, bool isClosePosition, uint256 commissionQuote);
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
|`refundColl`|`uint256`|The amount of collateral refunded.|
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
    override
    onlyAdapter
    whenNotPaused
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
    override
    onlyAdapter
    returns (uint256 liqLoan, uint128 liqColl, uint256 extraReward, int256 lossQuote);
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
|`lossQuote`|`int256`|The loss incurred by the platform.|


### getCurrentK

Returns the current K value of the pool.


```solidity
function getCurrentK() external view override returns (uint256);
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
    override
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
function getRewardConfig()
    external
    view
    override
    returns (uint256 rewardLiquidatorPercent, uint256 rewardPlatformPercent);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`rewardLiquidatorPercent`|`uint256`|The percentage of rewards for liquidators.|
|`rewardPlatformPercent`|`uint256`|The percentage of rewards for the platform.|


### getBorrowRateInfo

Returns the borrow rate information of the pool.


```solidity
function getBorrowRateInfo() external view override returns (uint256 borrowRatePerSec, uint256 lastUpdateRate);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`borrowRatePerSec`|`uint256`|The borrow rate per second.|
|`lastUpdateRate`|`uint256`|The timestamp of the last borrow rate update.|


### getAcceptableTimeInterval

Returns the acceptable time interval of the chainlink


```solidity
function getAcceptableTimeInterval() external view override returns (uint256);
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
    override
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
function getTokens() external view override returns (address token0, address token1);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`address`|The address of the first token.|
|`token1`|`address`|The address of the second token.|


### getPositionHealth

Calculates the health factor of a position.


```solidity
function getPositionHealth(uint256 posId) public view override returns (int256 healthFactor);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`posId`|`uint256`|The ID of the position.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`healthFactor`|`int256`|The health factor of the position.|


### getPrice

This function receives data from the chainlink and returns the current price of the  pair token0/token1

*It also checks if the price is older than the acceptable time interval and throws an error if it is.*


```solidity
function getPrice() public view override returns (uint256);
```

### _validatePosition

*Validates the position by checking its health factor. If the health factor is below the minimum
health percent, it reverts the transaction.*


```solidity
function _validatePosition(uint256 loan, uint256 collateral, uint256 price) internal view;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loan`|`uint256`|The loan amount of the position.|
|`collateral`|`uint256`|The collateral amount of the position.|
|`price`|`uint256`|The current price of the underlying asset.|


### _calculateLoanFees

Calculates the fees to be charged by the borrower for a given loan and K-value change.

*If the change in K-value is zero, this function returns (0, 0).
The commissionBase is calculated as the product of the loan amount and the change in K-value, divided by 100 and multiplied by 1e18 to account for the precision of the numbers.
The commissionQuote is calculated by converting the commissionBase to the quote currency using the current price.*


```solidity
function _calculateLoanFees(uint256 loan, uint256 k, uint256 currentK, uint256 price)
    internal
    view
    returns (uint256 commissionBase, uint256 commissionQuote);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loan`|`uint256`|The amount of the loan.|
|`k`|`uint256`|The previous K-value.|
|`currentK`|`uint256`|The current K-value.|
|`price`|`uint256`|The current price of the underlying asset.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`commissionBase`|`uint256`|The fees to be charged in base currency.|
|`commissionQuote`|`uint256`|The fees to be charged in quote currency.|


### _calcLiquidation

Calculates the amount to be liquidated based on the loan amount and collateral value.
The reward for the platform and liquidator are then calculated by taking a percentage of the remaining collateral value.
The function returns the amount to be liquidated, the reward for the platform, and the reward for the liquidator.


```solidity
function _calcLiquidation(uint256 loan, uint256 collateralInBaseCurrency)
    internal
    view
    returns (uint256 amountToLiquidation, uint256 rewPlatform, uint256 rewLiquidator);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`loan`|`uint256`|The amount of the loan.|
|`collateralInBaseCurrency`|`uint256`|The value of the collateral in base currency.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountToLiquidation`|`uint256`|The amount to be liquidated.|
|`rewPlatform`|`uint256`|The reward for the platform.|
|`rewLiquidator`|`uint256`|The reward for the liquidator.|


### _convertToBaseCurrency

Converts an amount of a token to its base currency equivalent.
The function takes an amount of a token and the current price of the token and returns the equivalent amount in base currency.


```solidity
function _convertToBaseCurrency(uint256 amount, uint256 price) internal view returns (uint256 amountInBaseCurrency);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of the token to be converted.|
|`price`|`uint256`|The current price of the token.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountInBaseCurrency`|`uint256`|The equivalent amount of the token in base currency.|


### _convertToQuoteCurrency

Converts an amount of a token to its quote currency equivalent.
The function takes an amount of a token and the current price of the token and returns the equivalent amount in quote currency.


```solidity
function _convertToQuoteCurrency(uint256 amount, uint256 price) internal view returns (uint256 amountInQuoteCurrency);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of the token to be converted.|
|`price`|`uint256`|The current price of the token.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountInQuoteCurrency`|`uint256`|The equivalent amount of the token in quote currency.|


### _calcK

*Calculates the current K value of the pool.
The formula for K is `K = borrowRatePerSec * (block.timestamp - lastUpdateRate) + k`, where borrowRatePerSec is the borrow rate per second,
lastUpdateRate is the timestamp of the last borrow rate update, and k is the previous K value.*


```solidity
function _calcK() internal view returns (uint256 k);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`k`|`uint256`|The current K value of the pool.|


### _calcHealth

function calculate health factor


```solidity
function _calcHealth(uint256 loan, uint256 collateralInBaseCurrency) internal view returns (int256 healthFactor);
```

### _rewardForExtraLiquidation

*Calculates the reward for extra liquidation.
The function returns the fixed reward for extra liquidation set by the configurator.*


```solidity
function _rewardForExtraLiquidation() internal view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The reward for extra liquidation.|


