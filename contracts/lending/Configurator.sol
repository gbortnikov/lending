// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AccessControl} from '@openzeppelin/contracts/access/AccessControl.sol';
import {Clones} from '@openzeppelin/contracts/proxy/Clones.sol';

import {IConfigurator} from './interfaces/IConfigurator.sol';
import {ITreasure} from './interfaces/ITreasure.sol';
import {IAdapter} from './interfaces/IAdapter.sol';
import {IPool} from './interfaces/IPool.sol';
import {IPoolUsd3} from './interfaces/IPoolUsd3.sol';
import {IPoolToken} from './interfaces/IPoolToken.sol';

import {IERC20, UniversalTransfer} from '../lending/UniversalTransfer.sol';

contract Configurator is IConfigurator, AccessControl {
    using UniversalTransfer for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256('ADMIN_ROLE');
    bytes32 public constant KEEPER_ROLE = keccak256('KEEPER_ROLE');

    address public immutable USD3;
    address public immutable EUR3;

    address internal _poolImplementation;
    address internal _poolTokenImplementation;
    address internal _adapter;
    address payable internal _treasure;

    /// @dev addrBaseToken => addrToken => addrPool
    mapping(address => mapping(address => address)) internal _pools;

    /// @dev addrToken => bool
    mapping(address => bool) internal _tokenMap;

    constructor(address _usd3, address _eur3) {
        if (_usd3 == address(0) || _eur3 == address(0)) {
            revert ZeroAddress();
        }
        USD3 = _usd3;
        EUR3 = _eur3;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isToken(address token) external view override returns (bool) {
        return _tokenMap[token];
    }

    // ------------------------ START POOL SETTINGS ------------------------

    function newPool(
        address token0,
        address token1,
        address chainlinkAggregator
    ) external override onlyRole(ADMIN_ROLE) returns (address pool) {
        if (token0 != USD3) {
            revert InvalidPair(token0, token1);
        }
        pool = _createPool(token0, token1, chainlinkAggregator);

        _pools[token0][token1] = pool;
        _tokenMap[token1] = true;

        emit NewPool({token0: token0, token1: token1, pool: pool});
    }

    function newPoolToken(
        address token0,
        address token1,
        address chainlinkAggregator,
        address chainlinkAggregatorTokenUsd
    ) external onlyRole(ADMIN_ROLE) returns (address pool) {
        if (token0 != EUR3) {
            revert InvalidPair(token0, token1);
        }
        pool = _createPoolToken(token0, token1, chainlinkAggregator, chainlinkAggregatorTokenUsd);

        _pools[token0][token1] = pool;
        _tokenMap[token1] = true;

        emit NewPool({token0: token0, token1: token1, pool: pool});
    }

    function pausePool(address pool) external override onlyRole(ADMIN_ROLE) {
        IPool(pool).pause();
        emit PoolPaused({pool: pool, status: true});
    }

    function unpausePool(address pool) external override onlyRole(ADMIN_ROLE) {
        IPool(pool).unpause();
        emit PoolPaused({pool: pool, status: false});
    }

    function setHealthRewardConfig(
        address pool,
        uint256 newMinHealthPercent,
        uint256 newLiquidateHealthPercent,
        uint128 newHealthPurpose,
        uint256 newRewardLiquidatorPercent,
        uint256 newRewardPlatformPercent
    ) external override onlyRole(ADMIN_ROLE) {
        IPool(pool).setHealthRewardConfig(
            newMinHealthPercent,
            newLiquidateHealthPercent,
            newHealthPurpose,
            newRewardLiquidatorPercent,
            newRewardPlatformPercent
        );
        emit PoolHealthRewardConfigUpdated({
            pool: pool,
            minHealthPercent: newMinHealthPercent,
            liquidateHealthPercent: newLiquidateHealthPercent,
            healthPurpose: newHealthPurpose,
            rewardLiquidatorPercent: newRewardLiquidatorPercent,
            rewardPlatformPercent: newRewardPlatformPercent
        });
    }

    function setPoolConfig(
        address pool,
        address newDataFeed,
        uint256 newAcceptableTimeInterval
    ) external override onlyRole(ADMIN_ROLE) {
        if (pool == address(0) || newDataFeed == address(0)) {
            revert ZeroAddress();
        }
        IPoolUsd3(pool).setConfig(newDataFeed, newAcceptableTimeInterval);
        emit PoolConfigUpdated({pool: pool, dataFeed: newDataFeed, acceptableTimeInterval: newAcceptableTimeInterval});
    }

    function setPoolTokenConfig(
        address pool,
        address newDataFeed,
        uint256 newAcceptableTimeInterval,
        address newDataFeedTokenUsd
    ) external onlyRole(ADMIN_ROLE) {
        if (pool == address(0) || newDataFeed == address(0)) {
            revert ZeroAddress();
        }
        IPoolToken(pool).setConfig(newDataFeed, newAcceptableTimeInterval, newDataFeedTokenUsd);
        emit PoolTokenConfigUpdated({
            pool: pool,
            dataFeed: newDataFeed,
            acceptableTimeInterval: newAcceptableTimeInterval,
            dataFeedTokenUsd: newDataFeedTokenUsd
        });
    }

    function setPoolExtraReward(address pool, uint256 extraReward) external override onlyRole(ADMIN_ROLE) {
        IPool(pool).setExtraReward(extraReward);
        emit PoolExtraRewardUpdated({pool: pool, extraReward: extraReward});
    }

    function setPoolBorrowRate(address pool, uint256 borrowRatePerYear) external override onlyRole(ADMIN_ROLE) {
        IPool(pool).setBorrowRate(borrowRatePerYear);
        emit PoolBorrowRateUpdated({pool: pool, borrowRatePerYear: borrowRatePerYear});
    }

    function setImplementationPool(address impl) external override onlyRole(ADMIN_ROLE) {
        if (impl == address(0)) {
            revert ZeroAddress();
        }
        _poolImplementation = impl;
        emit ImplementationPoolUpdated({impl: impl});
    }

    function setPoolMinLoan(address pool, uint256 newMinLoan) external override onlyRole(ADMIN_ROLE) {
        IPool(pool).setMinLoan(newMinLoan);
    }

    function getImplementationPool() external view override returns (address) {
        return _poolImplementation;
    }

    function getPool(address token0, address token1) external view override returns (address) {
        return _pools[token0][token1];
    }

    function _createPool(address token0, address token1, address chainlinkAggregator) internal returns (address pool) {
        pool = Clones.clone(_poolImplementation);
        IPoolUsd3(pool).initialize(token0, token1, chainlinkAggregator, _adapter, address(this));
    }

    function _createPoolToken(
        address token0,
        address token1,
        address chainlinkAggregator,
        address chainlinkAggregatorTokenUsd
    ) internal returns (address pool) {
        pool = Clones.clone(_poolTokenImplementation);
        IPoolToken(pool).initialize(
            token0,
            token1,
            chainlinkAggregator,
            _adapter,
            address(this),
            chainlinkAggregatorTokenUsd
        );
    }

    // ------------------------ END POOL SETTINGS ------------------------

    // ------------------------ START ADAPTER SETTINGS ------------------------

    function setAdapter(address adapter) external override onlyRole(ADMIN_ROLE) {
        _adapter = adapter;
        if (adapter == address(0)) {
            revert ZeroAddress();
        }
        emit AdapterUpdated({adapter: adapter});
    }

    function pauseAdapter() external override onlyRole(ADMIN_ROLE) {
        IAdapter(_adapter).pause();
        emit AdapterPaused({adapter: _adapter, status: true});
    }

    function unpauseAdapter() external override onlyRole(ADMIN_ROLE) {
        IAdapter(_adapter).unpause();
        emit AdapterPaused({adapter: _adapter, status: false});
    }

    function setAdapterEntryFee(uint256 fee) external override onlyRole(ADMIN_ROLE) {
        IAdapter(_adapter).setEntryFee(fee);
    }

    function getAdapter() external view override returns (address) {
        return _adapter;
    }

    // ------------------------ END ADAPTER SETTINGS ------------------------

    // ------------------------ START TREASURE SETTINGS ------------------------

    function setTreasure(address payable treasure) external override onlyRole(ADMIN_ROLE) {
        _treasure = treasure;
        if (treasure == address(0)) {
            revert ZeroAddress();
        }
        emit TreasureUpdated({treasure: treasure});
    }

    function refund(address token, uint256 amount) external payable override onlyRole(KEEPER_ROLE) {
        IERC20(token).universalTransferFrom(msg.sender, _treasure, amount);
        ITreasure(_treasure).refund(token, msg.sender, amount);
        emit Deposit({token: token, account: msg.sender, amount: amount});
    }

    function investCollateral(address token, address to, uint256 amount) external override onlyRole(KEEPER_ROLE) {
        ITreasure(_treasure).investCollateral(token, to, amount);
        emit Withdraw({token: token, account: to, amount: amount});
    }

    function withdrawTaxBorrow(address token, address to, uint256 amount) external override onlyRole(KEEPER_ROLE) {
        ITreasure(_treasure).withdrawTaxBorrow(token, to, amount);
        emit WithdrawTax({token: token, account: to, amount: amount});
    }

    function withdrawTaxLiquidate(address token, address to, uint256 amount) external override onlyRole(KEEPER_ROLE) {
        ITreasure(_treasure).withdrawTaxLiquidate(token, to, amount);
        emit WithdrawTax({token: token, account: to, amount: amount});
    }

    function replenishLosses(address token, uint256 amount) external onlyRole(KEEPER_ROLE) {
        IERC20(token).universalTransferFrom(msg.sender, _treasure, amount);
        ITreasure(_treasure).replenishLosses(token, amount);
        emit ReplenishLosses({token: token, account: msg.sender, amount: amount});
    }

    function withdrawLiquidateCollateral(
        address token,
        address to,
        uint256 amount
    ) external override onlyRole(KEEPER_ROLE) {
        ITreasure(_treasure).withdrawLiquidateCollateral(token, to, amount);
    }

    // ------------------------ END TREASURE SETTINGS ------------------------
}
