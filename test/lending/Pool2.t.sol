// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console, Vm} from 'forge-std/src/Test.sol';
import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {Erc20Mock} from 'contracts/mock/Erc20Mock.sol';
import {IPoolUsd3, Pool} from 'contracts/lending/Pool.sol';

import {AggregatorV3Interface} from 'contracts/lending/external/AggregatorV3Interface.sol';

contract PoolTest is Test {
    Erc20Mock public usd3;
    address public ampl = 0xD46bA6D942050d489DBd938a2C909A5d5039A161;

    address chainlinkAggregator = 0xe20CA8D7546932360e37E9D72c1a47334af57706; // AMPL/USD

    Pool pool;

    address user = makeAddr('user');
    address user2 = makeAddr('user2');
    address adapter = makeAddr('adapter');
    address configurator = makeAddr('configurator');

    uint256 newLiquidateHealthPercent = 10 * 100;
    uint128 newHealthPurpose = 30 * 100;
    uint256 newMinHealthPercent = 0;
    uint256 acceptableTimeInterval = 2 days;
    uint256 rewardLiquidatorPercent = 0;
    uint256 rewardPlatformPercent = 0;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString('ALCHEMY_RPC'), 20008600);
        vm.selectFork(forkId);

        usd3 = new Erc20Mock('USD3', 'USD3');
        pool = new Pool();

        pool.initialize(address(usd3), address(ampl), chainlinkAggregator, adapter, configurator);
    }

    function test_borrow() public {
        vm.startPrank(adapter);

        uint128 loanUSD3 = 1000e18;
        uint128 collateralAMPL = 1000e18;
        uint256 posId = 0;

        pool.borrow(loanUSD3, collateralAMPL, posId);

        (IPoolUsd3.Position memory position, int256 healthFactor, , ) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 1750, 0.01e18); // d = 1%
        assertApproxEqRel(position.collateral, collateralAMPL, 0);
        assertApproxEqRel(position.loan, loanUSD3, 0);
        assertApproxEqRel(pool.getPrice(), 1.213e18, 0.01e18); // d = 1%

        vm.stopPrank();
    }

    function test_borrowMore() public {
        vm.startPrank(adapter);
        uint128 loanUSD3 = 1000e18;
        uint128 collateralAMPL = 1000e18;
        uint256 posId = 0;

        pool.borrow(loanUSD3, collateralAMPL, posId);

        uint128 addCollateralAMPL = 100e18;
        uint128 addLoanUSD3 = 0;

        (IPoolUsd3.Position memory position, int256 healthFactor, , ) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 1750, 0.01e18); // d = 1%
        assertApproxEqRel(position.collateral, collateralAMPL, 0);
        assertApproxEqRel(position.loan, loanUSD3, 0);
        assertApproxEqRel(pool.getPrice(), 1.213e18, 0.01e18); // d = 1%

        pool.borrowMore(posId, addCollateralAMPL, addLoanUSD3);

        (IPoolUsd3.Position memory position2, int256 healthFactor2, , ) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor2, 2500, 0.01e18); // d = 1%
        assertEq(position2.collateral, collateralAMPL + addCollateralAMPL);
        assertEq(position2.loan, loanUSD3 + addLoanUSD3);

        vm.stopPrank();
    }

    function test_repay() public {
        vm.startPrank(adapter);

        uint128 loanUSD3 = 1000e18;
        uint128 loanRepayment = 100e18;
        uint128 collateralAMPL = 1000e18;
        uint256 posId = 0;
        pool.borrow(loanUSD3, collateralAMPL, posId);
        pool.repay(loanRepayment, posId, 0);

        (IPoolUsd3.Position memory position, int256 healthFactor, , ) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 2580, 0.01e18); // d = 1%
        assertApproxEqRel(position.collateral, collateralAMPL, 0);
        assertApproxEqRel(position.loan, loanUSD3 - loanRepayment, 0);

        uint128 refundCollateral = 100e18;
        pool.repay(0, posId, refundCollateral);

        (IPoolUsd3.Position memory position2, int256 healthFactor2, , ) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor2, 1750, 0.01e18); // d = 1%
        assertApproxEqRel(position2.collateral, collateralAMPL - refundCollateral, 0);
        assertApproxEqRel(position2.loan, loanUSD3 - loanRepayment, 0);

        vm.stopPrank();
    }

    function test_liquidation() public {
        _setConfig(address(pool));

        vm.startPrank(adapter);

        uint128 loanUSD3 = 1000e18;
        uint128 collateralAMPL = 1000e18;
        uint256 posId = 0;

        pool.borrow(loanUSD3, collateralAMPL, posId);
        int256 healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 1750, 0.01e18); // d = 1%
        _setPrice(1.1 * 1e18);
        healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 900, 0.01e18); // d = 1%

        pool.liquidate(posId);

        (IPoolUsd3.Position memory position, int256 healthFactor2, , ) = pool.getInfoPosition(posId);
        assertApproxEqRel(position.collateral, 303e18, 0.001e18);
        assertApproxEqRel(position.loan, 233.3e18, 0.001e18);
        assertApproxEqRel(healthFactor2, int128(newHealthPurpose), 0.001e18); //0.1%

        vm.stopPrank();
    }

    function _setPrice(int256 newPrice) internal {
        vm.mockCall(
            address(chainlinkAggregator),
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, newPrice, block.timestamp, block.timestamp, 0)
        );
        assertApproxEqRel(pool.getPrice(), uint256(newPrice), 0.01e18); // d = 1%
    }

    function _setConfig(address addrPool) internal {
        vm.startPrank(configurator);
        Pool(addrPool).setConfig(chainlinkAggregator, acceptableTimeInterval);
        Pool(addrPool).setHealthRewardConfig(
            newMinHealthPercent,
            newLiquidateHealthPercent,
            newHealthPurpose,
            rewardLiquidatorPercent,
            rewardPlatformPercent
        );
        vm.stopPrank();
    }
}
