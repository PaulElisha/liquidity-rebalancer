// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiquidityRebalancer {
    function rebalanceLiquidity(
        int24 oldTickLower,
        int24 oldTickUpper,
        uint128 liquidity,
        int24 tickLower,
        int24 tickUpper
    ) external;
}
