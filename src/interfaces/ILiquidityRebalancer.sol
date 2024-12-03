// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiquidityRebalancer {
    function calculateOptimalLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRationAX96,
        uint160 sqrtRationBX96,
        uint256 amount0,
        uint256 amount1
    ) external;
}
