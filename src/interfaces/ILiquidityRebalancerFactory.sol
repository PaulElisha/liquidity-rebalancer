// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILiquidityRebalancerFactory {
    event RebalancerCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint
    );

    function getRebalancer(
        address tokenA,
        address tokenB
    ) external view returns (address pair);

    function getAllRebalancers(uint) external view returns (address pair);

    function allRebalancersLength() external view returns (uint);

    function createRebalancer(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}
