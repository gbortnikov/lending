# IPoolUsd3
[Git Source](https://cardpay-test.com/git@gitlab.stablecoin/unlimit-defi/blob/d1e0d765d9ae6ec9dcb858457eae4dadf83338fd/contracts/lending/interfaces/IPoolUsd3.sol)

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
    address addrConfigurator
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


### setConfig

*Sets the configuration of the contract.
It allows the configurator to update the address of the Chainlink aggregator contract and the acceptable time interval.*


```solidity
function setConfig(address newDataFeed, uint256 newAcceptableTimeInterval) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newDataFeed`|`address`|The new address of the Chainlink aggregator contract.|
|`newAcceptableTimeInterval`|`uint256`|The new acceptable time interval.|


### getPrice

This function receives data from the chainlink and returns the current price of the  pair token0/token1

*It also checks if the price is older than the acceptable time interval and throws an error if it is.*


```solidity
function getPrice() external view returns (uint256);
```

