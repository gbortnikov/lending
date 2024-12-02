// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console, Vm} from 'forge-std/src/Test.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Treasure, ITreasure} from 'contracts/lending/Treasure.sol';

contract TreasureTest is Test {
    address user = makeAddr('user');
    address adapter = makeAddr('adapter');
    address configurator = makeAddr('configurator');

    Treasure treasure;
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    function setUp() public {
        uint256 forkId = vm.createFork(vm.envString('ALCHEMY_RPC'), 20008600);
        vm.selectFork(forkId);

        treasure = new Treasure();
        treasure.initialize(configurator, adapter);
    }

    function test_tax() public {
        (uint256 taxLiquidate, uint256 taxBorrow) = treasure.getTax(usdc);
        assertEq(taxLiquidate, 0);
        assertEq(taxBorrow, 0);
        deal(usdc, address(treasure), 300);

        vm.expectRevert(abi.encodeWithSelector(ITreasure.OnlyAdapter.selector));
        treasure.addTax(usdc, 100, 200);

        vm.startPrank(adapter);
        treasure.addTax(usdc, 100, 200);
        (taxLiquidate, taxBorrow) = treasure.getTax(usdc);
        assertEq(taxLiquidate, 100);
        assertEq(taxBorrow, 200);
        vm.stopPrank();

        vm.startPrank(configurator);
        treasure.withdrawTaxLiquidate(usdc, user, 100);
        (taxLiquidate, taxBorrow) = treasure.getTax(usdc);
        assertEq(taxLiquidate, 0);
        assertEq(taxBorrow, 200);

        treasure.withdrawTaxBorrow(usdc, user, 100);
        (taxLiquidate, taxBorrow) = treasure.getTax(usdc);
        assertEq(taxLiquidate, 0);
        assertEq(taxBorrow, 100);
        vm.stopPrank();
    }
}
