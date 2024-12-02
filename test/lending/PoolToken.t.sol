// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console, Vm} from 'forge-std/src/Test.sol';
import {IAccessControl} from '@openzeppelin/contracts/access/IAccessControl.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {Erc20Mock} from 'contracts/mock/Erc20Mock.sol';
import {PoolToken} from 'contracts/lending/PoolToken.sol';

import {AggregatorV3Interface} from 'contracts/lending/external/AggregatorV3Interface.sol';

contract PoolTest is Test {
    Erc20Mock public usd3;
    Erc20Mock public eur3;
    address public eth = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address chainlinkAggregator = 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419; // ETH/USD
    address chainlinkAggregatorUsdToken = 0xb49f677943BC038e9857d61E7d053CaA2C1734C1; // EUR/USD

    PoolToken pool;

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
        pool = new PoolToken();

        pool.initialize(
            address(usd3),
            address(eth),
            chainlinkAggregator,
            adapter,
            configurator,
            chainlinkAggregatorUsdToken
        );
    }

    function test_borrowMore() public {
        vm.startPrank(adapter);
        uint128 loanEUR3 = 1000e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;

        pool.borrow(loanEUR3, collateralETH, posId);

        uint128 addCollateralETH = 0.1e18;
        uint128 addLoanEUR3 = 0;

        (PoolToken.Position memory position, int256 healthFactor, , ) = pool.getInfoPosition(posId);
        assertEq(position.collateral, collateralETH);
        assertEq(position.loan, loanEUR3);
        assertApproxEqRel(healthFactor, 7150, 0.01e18); // d = 1%

        pool.borrowMore(posId, addCollateralETH, addLoanEUR3);

        (PoolToken.Position memory position2, int256 healthFactor2, , ) = pool.getInfoPosition(posId);

        assertApproxEqRel(healthFactor2, 7410, 0.01e18); // d = 1%
        assertEq(position2.collateral, collateralETH + addCollateralETH);
        assertEq(position2.loan, loanEUR3 + addLoanEUR3);

        vm.stopPrank();
    }

    function test_repay() public {
        vm.startPrank(adapter);

        uint128 loanEUR3 = 1000e18;
        uint128 loanRepayment = 500e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;
        pool.borrow(loanEUR3, collateralETH, posId);
        pool.repay(loanRepayment, posId, 0);
        int256 healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 8580, 0.01e18); // d = 1%

        vm.stopPrank();
    }

    function test_liquidation() public {
        _setConfig(address(pool));
        vm.startPrank(adapter);

        uint128 loanEUR3 = 2500e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;
        _setPrice(1.1 * 1e8, chainlinkAggregatorUsdToken);
        _setPrice(3750 * 1e8, chainlinkAggregator);

        pool.borrow(loanEUR3, collateralETH, posId);
        int256 healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 2400, 0.01e18); // d = 1%
        _setPrice(2750 * 1e8, chainlinkAggregator);

        healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 0, 0.01e18); // d = 1%

        pool.liquidate(posId);

        (PoolToken.Position memory position, int256 healthFactor2, uint256 commissionBase, ) = pool.getInfoPosition(
            posId
        );
        assertApproxEqRel(position.collateral, 0, 0.001e18);
        assertApproxEqRel(position.loan, 0, 0.001e18);
        assertEq(healthFactor2, 0);
        assertApproxEqRel(commissionBase, 0, 0);

        vm.stopPrank();
    }

    function test_liquidation2() public {
        _setConfig(address(pool));
        vm.startPrank(adapter);

        uint128 loanEUR3 = 2500e18;
        uint128 collateralETH = 1e18;
        uint256 posId = 0;
        _setPrice(1.1 * 1e8, chainlinkAggregatorUsdToken);
        _setPrice(3750 * 1e8, chainlinkAggregator);

        pool.borrow(loanEUR3, collateralETH, posId);
        int256 healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 2400, 0.01e18); // d = 1%
        _setPrice(2850 * 1e8, chainlinkAggregator);

        healthFactor = pool.getPositionHealth(posId);
        assertApproxEqRel(healthFactor, 315, 0.01e18); // d = 1%

        pool.liquidate(posId);

        (PoolToken.Position memory position, int256 healthFactor2, uint256 commissionBase, ) = pool.getInfoPosition(
            posId
        );
        assertApproxEqRel(position.collateral, 0.1052e18, 0.001e18);
        assertApproxEqRel(position.loan, 181.818e18, 0.001e18);
        assertEq(healthFactor2, 3000);
        assertApproxEqRel(commissionBase, 0, 0);

        vm.stopPrank();
    }

    function _setPrice(int256 newPrice, address chainlink) internal {
        vm.mockCall(
            address(chainlink),
            abi.encodeWithSelector(AggregatorV3Interface.latestRoundData.selector),
            abi.encode(0, newPrice, block.timestamp, block.timestamp, 0)
        );
        assertApproxEqRel(pool.getPrice(AggregatorV3Interface(chainlink)), uint256(newPrice), 0.01e18); // d = 1%
    }

    function _setConfig(address addrPool) internal {
        vm.startPrank(configurator);
        PoolToken(addrPool).setConfig(chainlinkAggregator, acceptableTimeInterval, chainlinkAggregatorUsdToken);
        PoolToken(addrPool).setHealthRewardConfig(
            newMinHealthPercent,
            newLiquidateHealthPercent,
            newHealthPurpose,
            rewardLiquidatorPercent,
            rewardPlatformPercent
        );
        vm.stopPrank();
    }
}
