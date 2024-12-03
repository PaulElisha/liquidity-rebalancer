// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../mocks/ERC20Mock.sol";
import "../../src/LiquidityRebalancerFactory.sol";

contract LiquidityRebalancerFactoryTest is Test {
    LiquidityRebalancerFactory liquidityRebalancerFactory;
    ERC20Mock token0;
    ERC20Mock token1;
    address private UserA;

    function setUp() {
        liquidityRebalancerFactory = new LiquidityRebalancerFactory();
        token0 = new ERC20Mock();
        token1 = ERC20Mock();

        UserA = makeAddr("UserA");
    }

    function testCreateRebalancer() public {
        vm.startPrank(UserA);
        liquidityRebalancerFactory.createRebalancer(
            token0,
            token1,
            0x12345abcdef
        );
        vm.stopPrank();
    }
}
