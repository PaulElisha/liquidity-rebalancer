// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiquidityRebalancer {
    function rebalanceLiquidity(
        int24 oldTickLower,
        int24 oldTickUpper,
        uint128 liquidity,
        int24 tickSpacing,
        uint256 priceAdjustmentFactor
    ) external;
}
