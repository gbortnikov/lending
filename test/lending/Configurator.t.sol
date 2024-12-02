// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console, Vm} from 'forge-std/src/Test.sol';
import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';

import {Erc20Mock} from 'contracts/mock/Erc20Mock.sol';
import {Configurator, IConfigurator} from 'contracts/lending/Configurator.sol';

import {IPoolUsd3, Pool} from 'contracts/lending/Pool.sol';
import {IAdapter, Adapter} from 'contracts/lending/Adapter.sol';
import {Treasure} from 'contracts/lending/Treasure.sol';

import {AggregatorV3Interface} from 'contracts/lending/external/AggregatorV3Interface.sol';

contract ConfiguratorTest is Test {
    Adapter public adapter;
    Configurator public configurator;
    Treasure treasure;
    Pool poolImpl;

    address public usd3;
    address public eur3;

    address public eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address chainlinkAggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD

    address user = makeAddr('user');
    address user2 = makeAddr('user2');
    address keeper = makeAddr('keeper');
    address admin = makeAddr('admin');

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString('ALCHEMY_RPC'), 20008600);
        vm.selectFork(forkId);

        usd3 = address(new Erc20Mock('USD3', 'USD3'));
        eur3 = address(new Erc20Mock('EUR3', 'EUR3'));
        poolImpl = new Pool();
        configurator = new Configurator(usd3, eur3);
        treasure = new Treasure();
        adapter = new Adapter();

        adapter.initialize(address(configurator), payable(address(treasure)));
        treasure.initialize(address(configurator), address(adapter));

        configurator.grantRole(configurator.ADMIN_ROLE(), admin);
        vm.startPrank(admin);

        configurator.setImplementationPool(address(poolImpl));
        configurator.setTreasure(payable(address(treasure)));
        configurator.setAdapter(address(adapter));
        vm.stopPrank();
    }

    function test_newPool() public {
        vm.startPrank(user);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                user,
                configurator.ADMIN_ROLE()
            )
        );
        configurator.newPool(usd3, eth, chainlinkAggregator);
        vm.stopPrank();
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(IConfigurator.InvalidPair.selector, eth, usd3));
        configurator.newPool(eth, usd3, chainlinkAggregator);
        vm.stopPrank();

        _createPool(usd3, eth);
    }

    function test_poolAdminFunctions() public {
        address pool = _createPool(usd3, eth);

        vm.startPrank(admin);

        configurator.pausePool(pool);
        assertEq(Pool(pool).paused(), true);

        configurator.unpausePool(pool);
        assertEq(Pool(pool).paused(), false);

        uint256 newMinHealthPercent = 100;
        uint256 newLiquidateHealthPercent = 200;
        uint128 newHealthPurpose = 300;
        uint256 newRewardLiquidatorPercent = 400;
        uint256 newRewardPlatformPercent = 500;
        uint256 newAcceptableTimeInterval = 99999;
        address newDataFeed = 0x547a514d5e3769680Ce22B2361c10Ea13619e8a9;
        uint256 newBorrowRate = 10e18;


        configurator.setHealthRewardConfig(
            pool,
            newMinHealthPercent,
            newLiquidateHealthPercent,
            newHealthPurpose,
            newRewardLiquidatorPercent,
            newRewardPlatformPercent
        );
        (int256 minHealthPercent, int256 liquidateHealthPercent, uint128 healthPurpose) = Pool(pool).getHealthConfig();
        assertEq(minHealthPercent, int256(newMinHealthPercent));
        assertEq(liquidateHealthPercent, int256(newLiquidateHealthPercent));
        assertEq(healthPurpose, newHealthPurpose);

        (uint256 rewardLiquidatorPercent, uint256 rewardPlatformPercent) = Pool(pool).getRewardConfig();
        assertEq(rewardLiquidatorPercent, newRewardLiquidatorPercent);
        assertEq(rewardPlatformPercent, newRewardPlatformPercent);

        configurator.setPoolConfig(pool, newDataFeed, newAcceptableTimeInterval);
        assertEq(address(Pool(pool).dataFeed()), newDataFeed);
        assertEq(Pool(pool).getAcceptableTimeInterval(), newAcceptableTimeInterval);

        configurator.setPoolBorrowRate(pool, newBorrowRate);
        (uint256 borrowRatePerSec, uint256 lastUpdateRate) = Pool(pool).getBorrowRateInfo();

        assertEq(borrowRatePerSec, newBorrowRate / 365 days);
        assertEq(lastUpdateRate, block.timestamp);
        vm.stopPrank();
    }

    function test_adapterAdminFunctions() public {
        vm.startPrank(admin);
        assertEq(address(configurator.getAdapter()), address(adapter));

        configurator.pauseAdapter();
        assertEq(adapter.paused(), true);
        configurator.unpauseAdapter();
        assertEq(adapter.paused(), false);
        vm.stopPrank();
    }

    function test_treasureAdminFunctions() public {
        configurator.grantRole(configurator.KEEPER_ROLE(), keeper);

        vm.startPrank(keeper);
        uint256 amount = 100e18;
        deal(address(usd3), keeper, amount);
        IERC20(usd3).approve(address(configurator), amount);
        configurator.refund(usd3, amount);
        assertEq(treasure.balanceOf(usd3), amount);
        configurator.investCollateral(usd3, keeper, amount);
        assertEq(treasure.balanceOf(usd3), 0);

        amount = 1e18;
        deal(keeper, amount);
        configurator.refund{value: amount}(eth, amount);
        assertEq(treasure.balanceOf(eth), amount);

        configurator.investCollateral(eth, keeper, amount);
        assertEq(treasure.balanceOf(eth), 0);

        vm.stopPrank();
    }

    function _createPool(address token0, address token1) internal returns (address pool) {
        vm.startPrank(admin);
        pool = configurator.newPool(token0, token1, chainlinkAggregator);
        (address t0, address t1) = IPoolUsd3(pool).getTokens();
        assertEq(t0, token0);
        assertEq(t1, token1);

        vm.stopPrank();
    }
}
