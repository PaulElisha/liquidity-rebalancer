// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import "../src/LiquidityRebalancerFactory.sol";
import "../test/mocks/ERC20Mock.sol";

contract DeployLiquidityRebalancerFactory is Script {
    LiquidityRebalancerFactory public liquidityRebalancerFactory;

    function run() public {
        vm.startBroadcast();

        liquidityRebalancerFactory = new LiquidityRebalancerFactory();

        vm.stopBroadcast();
    }

    function liquidityRebalancerFactory()
        public
        returns (LiquidityRebalancerFactory)
    {}
}
