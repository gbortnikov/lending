// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {IPool} from './IPool.sol';

interface IPoolUsd3 is IPool {
    /// Initialize the contract with the initial values of the variables.
    /// This function is called during the contract deployment.
    /// @param token0: The address of the first token in the pool.
    /// @param token1: The address of the second token in the pool.
    /// @param chainlinkAggregator: The address of the Chainlink aggregator contract.
    /// @param addrAdapter: The address of the adapter contract.
    /// @param addrConfigurator: The address of the configurator contract.
    function initialize(
        address token0,
        address token1,
        address chainlinkAggregator,
        address addrAdapter,
        address addrConfigurator
    ) external;

    /// @dev Sets the configuration of the contract.
    /// It allows the configurator to update the address of the Chainlink aggregator contract and the acceptable time interval.
    /// @param newDataFeed The new address of the Chainlink aggregator contract.
    /// @param newAcceptableTimeInterval The new acceptable time interval.
    function setConfig(address newDataFeed, uint256 newAcceptableTimeInterval) external;

    /// @notice This function receives data from the chainlink and returns the current price of the  pair token0/token1
    /// @dev It also checks if the price is older than the acceptable time interval and throws an error if it is.
    function getPrice() external view returns (uint256);
}
