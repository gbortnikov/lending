# IConfigurator
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/interfaces/IConfigurator.sol)


## Functions
### isToken


```solidity
function isToken(address token) external view returns (bool);
```

### newPool


```solidity
function newPool(address token0, address token1, address chainlinkAggregator) external returns (address pool);
```

### pausePool


```solidity
function pausePool(address pool) external;
```

### unpausePool


```solidity
function unpausePool(address pool) external;
```

### setHealthRewardConfig


```solidity
function setHealthRewardConfig(
    address pool,
    uint256 newMinHealthPercent,
    uint256 newLiquidateHealthPercent,
    uint128 newHealthPurpose,
    uint256 newRewardLiquidatorPercent,
    uint256 newRewardPlatformPercent
) external;
```

### setPoolConfig


```solidity
function setPoolConfig(address pool, address newDataFeed, uint256 newAcceptableTimeInterval) external;
```

### setPoolBorrowRate


```solidity
function setPoolBorrowRate(address pool, uint256 borrowRatePerYear) external;
```

### setPoolExtraReward


```solidity
function setPoolExtraReward(address pool, uint256 extraReward) external;
```

### setImplementationPool


```solidity
function setImplementationPool(address impl) external;
```

### setPoolMinLoan


```solidity
function setPoolMinLoan(address pool, uint256 newMinLoan) external;
```

### getImplementationPool


```solidity
function getImplementationPool() external view returns (address);
```

### getPool


```solidity
function getPool(address token0, address token1) external view returns (address);
```

### setAdapter


```solidity
function setAdapter(address adapter) external;
```

### pauseAdapter


```solidity
function pauseAdapter() external;
```

### unpauseAdapter


```solidity
function unpauseAdapter() external;
```

### setAdapterEntryFee


```solidity
function setAdapterEntryFee(uint256 fee) external;
```

### getAdapter


```solidity
function getAdapter() external view returns (address);
```

### setTreasure


```solidity
function setTreasure(address payable treasure) external;
```

### refund


```solidity
function refund(address token, uint256 amount) external payable;
```

### investCollateral


```solidity
function investCollateral(address token, address to, uint256 amount) external;
```

### withdrawTaxBorrow


```solidity
function withdrawTaxBorrow(address token, address to, uint256 amount) external;
```

### withdrawTaxLiquidate


```solidity
function withdrawTaxLiquidate(address token, address to, uint256 amount) external;
```

### withdrawLiquidateCollateral


```solidity
function withdrawLiquidateCollateral(address token, address to, uint256 amount) external;
```

## Events
### NewPool

```solidity
event NewPool(address token0, address token1, address pool);
```

### PoolPaused

```solidity
event PoolPaused(address pool, bool status);
```

### PoolHealthRewardConfigUpdated

```solidity
event PoolHealthRewardConfigUpdated(
    address pool,
    uint256 minHealthPercent,
    uint256 liquidateHealthPercent,
    uint128 healthPurpose,
    uint256 rewardLiquidatorPercent,
    uint256 rewardPlatformPercent
);
```

### PoolConfigUpdated

```solidity
event PoolConfigUpdated(address pool, address dataFeed, uint256 acceptableTimeInterval);
```

### PoolTokenConfigUpdated

```solidity
event PoolTokenConfigUpdated(address pool, address dataFeed, uint256 acceptableTimeInterval, address dataFeedTokenUsd);
```

### PoolBorrowRateUpdated

```solidity
event PoolBorrowRateUpdated(address pool, uint256 borrowRatePerYear);
```

### ImplementationPoolUpdated

```solidity
event ImplementationPoolUpdated(address impl);
```

### PoolRewardConfigUpdated

```solidity
event PoolRewardConfigUpdated(address pool, uint256 rewardLiquidatorPercent, uint256 rewardPlatformPercent);
```

### PoolRewardUpdated

```solidity
event PoolRewardUpdated(address pool, address reward, uint256 rewardAmount);
```

### AdapterUpdated

```solidity
event AdapterUpdated(address adapter);
```

### AdapterPaused

```solidity
event AdapterPaused(address adapter, bool status);
```

### TreasureUpdated

```solidity
event TreasureUpdated(address treasure);
```

### Deposit

```solidity
event Deposit(address token, address account, uint256 amount);
```

### Withdraw

```solidity
event Withdraw(address token, address account, uint256 amount);
```

### WithdrawTax

```solidity
event WithdrawTax(address token, address account, uint256 amount);
```

### PoolExtraRewardUpdated

```solidity
event PoolExtraRewardUpdated(address pool, uint256 extraReward);
```

### ReplenishLosses

```solidity
event ReplenishLosses(address token, address account, uint256 amount);
```

## Errors
### InvalidPair

```solidity
error InvalidPair(address token0, address token1);
```

### ZeroAddress

```solidity
error ZeroAddress();
```

