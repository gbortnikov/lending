// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console, Vm} from 'forge-std/src/Test.sol';
import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {Erc20Mock} from 'contracts/mock/Erc20Mock.sol';
import {IPoolUsd3, Pool} from 'contracts/lending/Pool.sol';
import {IAdapter, Adapter} from 'contracts/lending/Adapter.sol';

import {AggregatorV3Interface} from 'contracts/lending/external/AggregatorV3Interface.sol';
import {Configurator} from 'contracts/lending/Configurator.sol';
import {Treasure} from 'contracts/lending/Treasure.sol';

contract AdapterTest is Test {
    Erc20Mock public usd3;
    Erc20Mock public eur3;
    address public eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address chainlinkAggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD

    Pool pool;
    Adapter adapter;

    address user = makeAddr('user');
    address user2 = makeAddr('user2');
    address configurator = makeAddr('configurator');
    address liquidator = makeAddr('liquidator');
    Treasure treasure;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString('ALCHEMY_RPC'), 20008600);
        vm.selectFork(forkId);

        usd3 = new Erc20Mock('USD3', 'USD3');
        pool = new Pool();
        adapter = new Adapter();
        treasure = new Treasure();

        pool.initialize(address(usd3), address(eth), chainlinkAggregator, address(adapter), configurator);
        adapter.initialize(configurator, payable(address(treasure)));
        treasure.initialize(address(configurator), address(adapter));

        vm.startPrank(configurator);
        deal(address(usd3), configurator, 100000e18);
        usd3.approve(address(treasure), 100000e18);
        deal(address(usd3), address(treasure), 100000e18);
        vm.stopPrank();

        deal(user, 100e18);
        _setConfig(address(pool));
    }

    function test_supply() public {
        address token = eth;
        uint256 amountCollateral = 1e18;
        vm.startPrank(user);
        _supply(token, amountCollateral / 2);
        _supply(token, amountCollateral / 2);

        assertEq(address(treasure).balance, amountCollateral);
        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(token, user);
        assertEq(availableCollateral, amountCollateral);
        assertEq(info.collateral, amountCollateral);
        assertEq(info.usedCollateral, 0);

        vm.stopPrank();
    }

    function test_withdrawCollateral() public {
        address token = eth;
        uint256 amountCollateral = 0.5e18;

        vm.startPrank(user);

        _supply(token, amountCollateral);
        _supply(token, amountCollateral);

        adapter.withdrawCollateral(token, amountCollateral);

        assertEq(address(treasure).balance, amountCollateral);
        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(token, user);
        assertEq(availableCollateral, amountCollateral);
        assertEq(info.collateral, amountCollateral);
        assertEq(info.usedCollateral, 0);

        adapter.withdrawCollateral(token, amountCollateral);

        assertEq(address(treasure).balance, 0);
        (info, availableCollateral) = adapter.getInfoCollateral(token, user);
        assertEq(availableCollateral, 0);
        assertEq(info.collateral, 0);
        assertEq(info.usedCollateral, 0);
    }

    function test_borrow() public {
        uint128 amountCollateral = 1e18;
        uint128 loanUSD3 = 1000e18;
        address token = eth;
        uint128 provision = amountCollateral / 3;

        vm.startPrank(user);

        _supply(token, amountCollateral);

        _borrow(loanUSD3, provision);
        assertEq(usd3.balanceOf(address(user)), loanUSD3);
        assertEq(adapter.counterId(), 1);
        (IAdapter.InfoPosition memory infoPosition, , , , ) = adapter.getFullInfoPosition(adapter.counterId() - 1);
        assertEq(infoPosition.pool, address(pool));
        assertEq(infoPosition.account, user);
        assertEq(uint8(infoPosition.status), uint8(IAdapter.PositionStatus.OPEN));

        _borrow(loanUSD3, provision);
        assertEq(usd3.balanceOf(address(user)), loanUSD3 + loanUSD3);
        assertEq(adapter.counterId(), 2);
        (infoPosition, , , , ) = adapter.getFullInfoPosition(adapter.counterId() - 1);
        assertEq(infoPosition.pool, address(pool));
        assertEq(infoPosition.account, user);
        assertEq(uint8(infoPosition.status), uint8(IAdapter.PositionStatus.OPEN));

        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(eth, user);
        assertEq(availableCollateral, amountCollateral - provision - provision);
        assertEq(info.collateral, amountCollateral);
        assertEq(info.usedCollateral, provision + provision);

        vm.stopPrank();
    }

    function test_borrowMore() public {
        uint128 amountCollateral = 1e18;
        uint128 loanUSD3 = 1000e18;
        address token = eth;
        uint128 provision = 0.33e18;

        vm.startPrank(user);

        _supply(token, amountCollateral);

        _borrow(loanUSD3, provision);
        assertEq(usd3.balanceOf(address(user)), loanUSD3);
        assertEq(adapter.counterId(), 1);
        (IAdapter.InfoPosition memory infoPosition, , , , ) = adapter.getFullInfoPosition(adapter.counterId() - 1);
        assertEq(infoPosition.pool, address(pool));
        assertEq(infoPosition.account, user);
        assertEq(uint8(infoPosition.status), uint8(IAdapter.PositionStatus.OPEN));

        skip(182.5 * 24 * 60 * 60);
        _setPrice(3550 * 1e8);

        uint256 idPosition = adapter.counterId() - 1;
        uint128 addCollateral = 0.1e18;
        uint128 addLoan = 0;
        adapter.borrowMore(idPosition, addCollateral, addLoan);

        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(eth, user);
        assertEq(availableCollateral, amountCollateral - provision - addCollateral);
        assertApproxEqRel(info.collateral, amountCollateral - 0.0281e18, 0.01e18);
        assertApproxEqRel(info.usedCollateral, provision + addCollateral - 0.0281e18, 0.01e18);
        assertEq(usd3.balanceOf(address(user)), loanUSD3 + addLoan);
    }

    function test_repay() public {
        vm.startPrank(user);
        uint128 amountCollateral = 1e18;
        address token = eth;
        _supply(token, amountCollateral);

        uint128 loanUSD3 = 1000e18;
        uint128 provision = 0.5e18;
        _borrow(loanUSD3, provision);

        uint256 idPosition = 0;
        uint128 loanRepayment = 100e18;
        uint128 refundCollateral = 0;
        usd3.approve(address(adapter), loanRepayment);
        adapter.repay(idPosition, loanRepayment, refundCollateral);
        assertEq(usd3.balanceOf(address(user)), loanUSD3 - loanRepayment);

        refundCollateral = 0.1e18;
        usd3.approve(address(adapter), loanRepayment);
        adapter.repay(idPosition, loanRepayment, refundCollateral);
        assertEq(usd3.balanceOf(address(user)), loanUSD3 - loanRepayment - loanRepayment);

        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(eth, user);
        assertEq(availableCollateral, amountCollateral - provision + refundCollateral);
        assertEq(info.collateral, amountCollateral);
        assertEq(info.usedCollateral, provision - refundCollateral);

        (IAdapter.InfoPosition memory infoPosition, , , , ) = adapter.getFullInfoPosition(adapter.counterId() - 1);
        assertEq(infoPosition.pool, address(pool));
        assertEq(infoPosition.account, user);
        assertEq(uint8(infoPosition.status), uint8(IAdapter.PositionStatus.OPEN));

        refundCollateral = 0.4e18;
        usd3.approve(address(adapter), loanUSD3 - loanRepayment - loanRepayment);
        adapter.repay(idPosition, loanUSD3 - loanRepayment - loanRepayment, 0);
        assertEq(usd3.balanceOf(address(user)), 0);

        (info, availableCollateral) = adapter.getInfoCollateral(eth, user);
        assertEq(availableCollateral, amountCollateral);
        assertEq(info.collateral, amountCollateral);
        assertEq(info.usedCollateral, 0);

        vm.stopPrank();
    }

    function test_repay2() public {
        vm.startPrank(user);
        uint128 amountCollateral = 1e18;
        address token = eth;
        _supply(token, amountCollateral);

        uint128 loanUSD3 = 1000e18;
        uint128 provision = 0.5e18;
        _borrow(loanUSD3, provision);
        skip(182.5 * 24 * 60 * 60);
        _setPrice(3550 * 1e8);

        uint256 idPosition = 0;
        uint128 loanRepayment = 100e18;
        uint128 refundCollateral = 0.1e18;
        usd3.approve(address(adapter), loanRepayment);
        adapter.repay(idPosition, loanRepayment, refundCollateral);
        assertEq(usd3.balanceOf(address(user)), loanUSD3 - loanRepayment);
        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(eth, user);
        assertApproxEqRel(info.collateral, 0.9714e18, 0.01e18);
        assertApproxEqRel(info.usedCollateral, 0.3714e18, 0.01e18);
        assertApproxEqRel(availableCollateral, amountCollateral - provision + refundCollateral, 0);

        vm.stopPrank();
    }

    function test_liquidate() public {
        vm.startPrank(user);
        uint128 amountCollateral = 1e18;
        address token = eth;
        _supply(token, amountCollateral);

        uint128 loanUSD3 = 1000e18;
        uint128 provision = 0.3e18;
        _borrow(loanUSD3, provision);
        _setPrice(3550 * 1e8);
        vm.stopPrank();

        vm.startPrank(liquidator);

        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(eth, user);
        uint256 idPosition = 0;
        adapter.liquidate(idPosition);
        assertGt(liquidator.balance, 0);

        (IAdapter.InfoCollateral memory info2, uint256 availableCollateral2) = adapter.getInfoCollateral(eth, user);
        assertGt(info.collateral, info2.collateral);
        assertGt(info.usedCollateral, info2.usedCollateral);
        assertEq(availableCollateral, availableCollateral2);

        vm.stopPrank();
    }

    function test_liquidate2() public {
        vm.startPrank(user);
        uint128 amountCollateral = 1e18;
        address token = eth;
        _supply(token, amountCollateral);

        uint128 loanUSD3 = 1000e18;
        uint128 provision = 0.34e18;

        _borrow(loanUSD3, provision);
        vm.stopPrank();

        skip(182.5 * 24 * 60 * 60);
        _setPrice(3550 * 1e8);

        vm.startPrank(liquidator);

        uint256 idPosition = 0;
        adapter.liquidate(idPosition);

        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(eth, user);
        assertApproxEqRel(info.collateral, 0.75e18, 0.01e18);
        assertApproxEqRel(info.usedCollateral, 0.09e18, 0.01e18);
        assertApproxEqRel(availableCollateral, amountCollateral - provision, 0.01e18);

        vm.stopPrank();
    }

    function test_extraLiquidate() public {
        vm.startPrank(user);
        uint128 amountCollateral = 1.1e18;
        address token = eth;
        _supply(token, amountCollateral);

        uint128 loanUSD3 = 3000e18;
        uint128 provision = 1e18;

        _borrow(loanUSD3, provision);
        vm.stopPrank();
        skip(182.5 * 24 * 60 * 60);
        _setPrice(3000 * 1e8);

        vm.startPrank(liquidator);
        adapter.extraLiquidate(0);
        (
            IAdapter.InfoPosition memory infoPosition,
            IPoolUsd3.Position memory position,
            int256 health,
            uint256 commissionBase,
            uint256 commissionQuote
        ) = adapter.getFullInfoPosition(0);
        assertEq(health, 0);
        assertEq(commissionBase, 0);
        assertEq(commissionQuote, 0);
        assertEq(uint256(infoPosition.status), uint256(IAdapter.PositionStatus.CLOSED));
        assertEq(position.collateral, 0);
        assertEq(position.loan, 0);

        (IAdapter.InfoCollateral memory info, uint256 availableCollateral) = adapter.getInfoCollateral(eth, user);
        assertEq(info.collateral, amountCollateral - provision);
        assertEq(availableCollateral, amountCollateral - provision);
        assertEq(info.usedCollateral, 0);
    }

    function _supply(address token, uint256 amountCollateral) internal {
        vm.mockCall(address(configurator), abi.encodeWithSelector(Configurator.isToken.selector), abi.encode(true));
        adapter.supply{value: amountCollateral}(token, amountCollateral);
    }

    function _borrow(uint128 loanUSD3, uint128 provision) internal {
        vm.mockCall(
            address(configurator),
            abi.encodeWithSelector(Configurator.getPool.selector),
            abi.encode(address(pool))
        );
        adapter.borrow(address(usd3), address(eth), loanUSD3, provision);
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
        uint256 newLiquidateHealthPercent = 10 * 100;
        uint128 newHealthPurpose = 30 * 100;
        uint256 newMinHealthPercent = 0;
        uint256 acceptableTimeInterval = 2 days;
        uint256 rewardLiquidatorPercent = 500;
        uint256 rewardPlatformPercent = 500;
        uint256 borrowRate = 20e18;

        vm.startPrank(configurator);
        Pool(addrPool).setConfig(chainlinkAggregator, acceptableTimeInterval);
        Pool(addrPool).setHealthRewardConfig(
            newMinHealthPercent,
            newLiquidateHealthPercent,
            newHealthPurpose,
            rewardLiquidatorPercent,
            rewardPlatformPercent
        );
        Pool(addrPool).setBorrowRate(borrowRate); // 10%

        vm.stopPrank();
    }
}
