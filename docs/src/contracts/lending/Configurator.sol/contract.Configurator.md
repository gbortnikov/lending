# Configurator
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/Configurator.sol)

**Inherits:**
[IConfigurator](/contracts/lending/interfaces/IConfigurator.sol/interface.IConfigurator.md), AccessControl


## State Variables
### ADMIN_ROLE

```solidity
bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
```


### KEEPER_ROLE

```solidity
bytes32 public constant KEEPER_ROLE = keccak256("KEEPER_ROLE");
```


### USD3

```solidity
address public immutable USD3;
```


### EUR3

```solidity
address public immutable EUR3;
```


### _poolImplementation

```solidity
address internal _poolImplementation;
```


### _poolTokenImplementation

```solidity
address internal _poolTokenImplementation;
```


### _adapter

```solidity
address internal _adapter;
```


### _treasure

```solidity
address payable internal _treasure;
```


### _pools
*addrBaseToken => addrToken => addrPool*


```solidity
mapping(address => mapping(address => address)) internal _pools;
```


### _tokenMap
*addrToken => bool*


```solidity
mapping(address => bool) internal _tokenMap;
```


## Functions
### constructor


```solidity
constructor(address _usd3, address _eur3);
```

### isToken


```solidity
function isToken(address token) external view override returns (bool);
```

### newPool


```solidity
function newPool(address token0, address token1, address chainlinkAggregator)
    external
    override
    onlyRole(ADMIN_ROLE)
    returns (address pool);
```

### newPoolToken


```solidity
function newPoolToken(address token0, address token1, address chainlinkAggregator, address chainlinkAggregatorTokenUsd)
    external
    onlyRole(ADMIN_ROLE)
    returns (address pool);
```

### pausePool


```solidity
function pausePool(address pool) external override onlyRole(ADMIN_ROLE);
```

### unpausePool


```solidity
function unpausePool(address pool) external override onlyRole(ADMIN_ROLE);
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
) external override onlyRole(ADMIN_ROLE);
```

### setPoolConfig


```solidity
function setPoolConfig(address pool, address newDataFeed, uint256 newAcceptableTimeInterval)
    external
    override
    onlyRole(ADMIN_ROLE);
```

### setPoolTokenConfig


```solidity
function setPoolTokenConfig(
    address pool,
    address newDataFeed,
    uint256 newAcceptableTimeInterval,
    address newDataFeedTokenUsd
) external onlyRole(ADMIN_ROLE);
```

### setPoolExtraReward


```solidity
function setPoolExtraReward(address pool, uint256 extraReward) external override onlyRole(ADMIN_ROLE);
```

### setPoolBorrowRate


```solidity
function setPoolBorrowRate(address pool, uint256 borrowRatePerYear) external override onlyRole(ADMIN_ROLE);
```

### setImplementationPool


```solidity
function setImplementationPool(address impl) external override onlyRole(ADMIN_ROLE);
```

### setPoolMinLoan


```solidity
function setPoolMinLoan(address pool, uint256 newMinLoan) external override onlyRole(ADMIN_ROLE);
```

### getImplementationPool


```solidity
function getImplementationPool() external view override returns (address);
```

### getPool


```solidity
function getPool(address token0, address token1) external view override returns (address);
```

### _createPool


```solidity
function _createPool(address token0, address token1, address chainlinkAggregator) internal returns (address pool);
```

### _createPoolToken


```solidity
function _createPoolToken(
    address token0,
    address token1,
    address chainlinkAggregator,
    address chainlinkAggregatorTokenUsd
) internal returns (address pool);
```

### setAdapter


```solidity
function setAdapter(address adapter) external override onlyRole(ADMIN_ROLE);
```

### pauseAdapter


```solidity
function pauseAdapter() external override onlyRole(ADMIN_ROLE);
```

### unpauseAdapter


```solidity
function unpauseAdapter() external override onlyRole(ADMIN_ROLE);
```

### setAdapterEntryFee


```solidity
function setAdapterEntryFee(uint256 fee) external override onlyRole(ADMIN_ROLE);
```

### getAdapter


```solidity
function getAdapter() external view override returns (address);
```

### setTreasure


```solidity
function setTreasure(address payable treasure) external override onlyRole(ADMIN_ROLE);
```

### refund


```solidity
function refund(address token, uint256 amount) external payable override onlyRole(KEEPER_ROLE);
```

### investCollateral


```solidity
function investCollateral(address token, address to, uint256 amount) external override onlyRole(KEEPER_ROLE);
```

### withdrawTaxBorrow


```solidity
function withdrawTaxBorrow(address token, address to, uint256 amount) external override onlyRole(KEEPER_ROLE);
```

### withdrawTaxLiquidate


```solidity
function withdrawTaxLiquidate(address token, address to, uint256 amount) external override onlyRole(KEEPER_ROLE);
```

### replenishLosses


```solidity
function replenishLosses(address token, uint256 amount) external onlyRole(KEEPER_ROLE);
```

### withdrawLiquidateCollateral


```solidity
function withdrawLiquidateCollateral(address token, address to, uint256 amount)
    external
    override
    onlyRole(KEEPER_ROLE);
```

