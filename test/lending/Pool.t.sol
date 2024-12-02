// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console, Vm} from 'forge-std/src/Test.sol';
import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {Erc20Mock} from 'contracts/mock/Erc20Mock.sol';
import {IPoolUsd3, Pool} from 'contracts/lending/Pool.sol';

import {AggregatorV3Interface} from 'contracts/lending/external/AggregatorV3Interface.sol';

contract PoolTest is Test {
    Erc20Mock public usd3;
    Erc20Mock public eur3;
    address public eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address chainlinkAggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD

    Pool pool;

    address user = makeAddr('user');
    address user2 = makeAddr('user2');
    address adapter = makeAddr('adapter');
    address configurator = makeAddr('configurator');

    uint256 newLiquidateHealthPercent = 10 * 100;
    uint128 newHealthPurpose = 30 * 100;
    uint256 newMinHealthPercent = 0;
    uint256 acceptableTimeInterval = 2 days;
    uint256 rewardLiquidatorPercent = 500;
    uint256 rewardPlatformPercent = 500;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString('ALCHEMY_RPC'), 20008600);
        vm.selectFork(forkId);

        usd3 = new Erc20Mock('USD3', 'USD3');
        pool = new Pool();

        pool.initialize(address(usd3), address(eth), chainlinkAggregator, adapter, configurator);
    }

    function test_k() public {
        vm.startPrank(configurator);
        skip(182.5 * 24 * 60 * 60);
        uint256 k = pool.getCurrentK();
        assertEq(k, 0);

        pool.setBorrowRate(10e18); // 10%
        skip(182.5 * 24 * 60 * 60);

        k = pool.getCurrentK();
        assertApproxEqRel(k, 5e18, 0.01e18);

        pool.setBorrowRate(5e18); // 5%
        skip(182.5 * 24 * 60 * 60);

        k = pool.getCurrentK();
        assertApproxEqRel(k, 7.5e18, 0.01e18);

        pool.setBorrowRate(0); // 0%
        skip(182.5 * 24 * 60 * 60);

        k = pool.getCurrentK();
        assertApproxEqRel(k, 7.5e18, 0.01e18);

        pool.setBorrowRate(20e18); // 20%
        skip(2 * 365 * 24 * 60 * 60);

        k = pool.getCurrentK();
        assertApproxEqRel(k, 47.5e18, 0.01e18);

        vm.stopPrank();
    }

    function test_borrowMore() public {
        vm.startPrank(adapter);
        uint128 loanUSD3 = 2500e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;

        pool.borrow(loanUSD3, collateralETH, posId);

        uint128 addCollateralETH = 0.1e18;
        uint128 addLoanUSD3 = 0;

        (IPoolUsd3.Position memory position, int256 healthFactor, , ) = pool.getInfoPosition(posId);
        assertEq(position.collateral, collateralETH);
        assertEq(position.loan, loanUSD3);

        pool.borrowMore(posId, addCollateralETH, addLoanUSD3);

        (IPoolUsd3.Position memory position2, int256 healthFactor2, , ) = pool.getInfoPosition(posId);
        assertLt(healthFactor, healthFactor2);
        assertEq(position2.collateral, collateralETH + addCollateralETH);
        assertEq(position2.loan, loanUSD3 + addLoanUSD3);

        vm.stopPrank();
    }

    function test_borrowMore_withBorrowRate() public {
        vm.startPrank(configurator);

        pool.setBorrowRate(10e18); // 10%
        vm.stopPrank();

        vm.startPrank(adapter);

        uint128 loanUSD3 = 1000e18;
        uint128 collateralETH = 1e18;

        uint256 posId = 0;
        pool.borrow(loanUSD3, collateralETH, posId);
        (IPoolUsd3.Position memory position, int256 healthFactor, uint256 commissionBase, uint256 commissionQuote) = pool
            .getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 7373, 0);

        skip(182.5 * 24 * 60 * 60);
        _setPrice(3500 * 1e8);

        (position, healthFactor, commissionBase, commissionQuote) = pool.getInfoPosition(posId);

        assertApproxEqRel(healthFactor, 7101, 0);
        assertApproxEqRel(commissionBase, 50e18, 0.001e18);
        uint128 addColl = 0;
        uint128 addLoan = 1000e18;
        pool.borrowMore(posId, addColl, addLoan);

        (position, healthFactor, commissionBase, commissionQuote) = pool.getInfoPosition(posId);
        assertEq(position.loan, loanUSD3 + addLoan);
        assertApproxEqRel(healthFactor, 4202, 0);
        assertApproxEqRel(commissionBase, 0, 0);

        addColl = 1e18;
        addLoan = 0;
        pool.borrowMore(posId, addColl, addLoan);
        (position, healthFactor, commissionBase, commissionQuote) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 7122, 0);

        vm.stopPrank();
    }

    function test_repay() public {
        vm.startPrank(adapter);

        uint128 loanUSD3 = 1000e18;
        uint128 loanRepayment = 100e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;
        pool.borrow(loanUSD3, collateralETH, posId);
        pool.repay(loanRepayment, posId, 0);
        int256 healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 7600, 0.01e18); // d = 1%

        vm.stopPrank();
    }

    function test_repay_withBorrowRate() public {
        vm.startPrank(configurator);
        pool.setConfig(chainlinkAggregator, 9999999999999999);
        pool.setBorrowRate(10e18); // 10%
        skip(60);

        vm.stopPrank();

        vm.startPrank(adapter);

        uint128 loanUSD3 = 1000e18;
        uint128 loanRepayment = 100e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;
        pool.borrow(loanUSD3, collateralETH, posId);
        (IPoolUsd3.Position memory position, int256 healthFactor, uint256 commissionBase, uint256 commissionQuote) = pool
            .getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 7373, 0);

        skip(182.5 * 24 * 60 * 60);
        (position, healthFactor, commissionBase, commissionQuote) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 7338, 0);
        assertApproxEqRel(commissionBase, 50e18, 0.001e18);

        pool.repay(loanRepayment, posId, 0);
        (position, healthFactor, commissionBase, commissionQuote) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 7604, 0);
        assertApproxEqRel(commissionBase, 0, 0);

        vm.stopPrank();
    }

    function test_liquidation() public {
        _setConfig(address(pool));

        vm.startPrank(adapter);

        uint128 loanUSD3 = 2500e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;

        pool.borrow(loanUSD3, collateralETH, posId);
        int256 healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 3100, 0.01e18); // d = 1%
        _setPrice(2750 * 1e8);

        healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 810, 0.01e18); // d = 1%

        pool.liquidate(posId);

        (IPoolUsd3.Position memory position, int256 healthFactor2, uint256 commissionBase, ) = pool.getInfoPosition(posId);
        assertApproxEqRel(position.collateral, 0.2727e18, 0.001e18);
        assertApproxEqRel(position.loan, 500.333e18, 0.001e18);
        assertEq(healthFactor2, int128(newHealthPurpose));
        assertApproxEqRel(commissionBase, 0, 0);

        vm.stopPrank();
    }

    function test_liquidation_withBorrowRate() public {
        _setConfig(address(pool));
        vm.startPrank(configurator);
        pool.setConfig(chainlinkAggregator, 9999999999999999);
        pool.setBorrowRate(10e18); // 10%
        skip(60);

        vm.stopPrank();

        vm.startPrank(adapter);

        uint128 loanUSD3 = 2500e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;
        pool.borrow(loanUSD3, collateralETH, posId);
        (IPoolUsd3.Position memory position, int256 healthFactor, uint256 commissionBase, uint256 commissionQuote) = pool
            .getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 3100, 0.01e18); // d = 1%

        skip(182.5 * 24 * 60 * 60);
        _setPrice(2750 * 1e8);

        (position, healthFactor, commissionBase, commissionQuote) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 428, 0.01e18); // d = 1%
        assertApproxEqRel(commissionBase, 125e18, 0.001e18);

        pool.liquidate(posId);

        (position, healthFactor, commissionBase, commissionQuote) = pool.getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 3000, 0.01e18); // d = 1%
        assertApproxEqRel(commissionBase, 0, 0.001e18);
    }

    function test_extraLiquidation_withBorrowRate() public {
        _setConfig(address(pool));
        vm.startPrank(configurator);
        pool.setConfig(chainlinkAggregator, 9999999999999999);
        uint256 borrowRate = 10e18; // 10%
        uint256 extraReward = 0.01e18;
        pool.setBorrowRate(borrowRate);
        pool.setExtraReward(extraReward);
        skip(60);

        vm.stopPrank();

        vm.startPrank(adapter);

        uint128 loanUSD3 = 2500e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;
        pool.borrow(loanUSD3, collateralETH, posId);
        (IPoolUsd3.Position memory position, int256 healthFactor, uint256 commissionBase, uint256 commissionQuote) = pool
            .getInfoPosition(posId);
        assertApproxEqRel(healthFactor, 3100, 0.01e18); // d = 1%

        skip(182.5 * 24 * 60 * 60);
        _setPrice(2350 * 1e8);

        (position, healthFactor, commissionBase, commissionQuote) = pool.getInfoPosition(posId);
        assertLt(healthFactor, 0);

        (uint256 liqLoan, uint128 liqColl, uint256 rewLiquidator, int256 loss) = pool.extraLiquidate(posId);
        assertApproxEqRel(loss, int256(-0.0638e18), 0.01e18);
        assertEq(liqLoan, loanUSD3);
        assertEq(liqColl, collateralETH);
        assertEq(rewLiquidator, extraReward);
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
