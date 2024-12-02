# IPoolToken
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/interfaces/IPoolToken.sol)

**Inherits:**
[IPool](/contracts/lending/interfaces/IPool.sol/interface.IPool.md)


## Functions
### initialize

Initialize the contract with the initial values of the variables.
This function is called during the contract deployment.


```solidity
function initialize(
    address token0,
    address token1,
    address chainlinkAggregator,
    address addrAdapter,
    address addrConfigurator,
    address chainlinkAggregatorTokenUsd
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token0`|`address`||
|`token1`|`address`||
|`chainlinkAggregator`|`address`||
|`addrAdapter`|`address`||
|`addrConfigurator`|`address`||
|`chainlinkAggregatorTokenUsd`|`address`||


### setConfig


```solidity
function setConfig(address newDataFeed, uint256 newAcceptableTimeInterval, address newDataFeedTokenUsd) external;
```

### getPrice

This function receives data from the chainlink and returns the current price of the  pair token0/token1

*It also checks if the price is older than the acceptable time interval and throws an error if it is.*


```solidity
function getPrice(AggregatorV3Interface feed) external view returns (uint256);
```

