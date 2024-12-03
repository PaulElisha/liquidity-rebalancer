// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LiquidityRebalancer.sol";
import "./interfaces/ILiquidityRebalancerFactory.sol";

contract LiquidityRebalancerFactory is ILiquidityRebalancerFactory {
    address public owner;
    mapping(address => mapping(address => address)) public getRebalancer;
    address[] public allRebalancers;

    constructor() {
        owner = msg.sender;
    }

    function createRebalancer(
        address tokenA,
        address tokenB,
        address pool
    ) external returns (address rebalancer) {
        require(
            token0 != token1,
            "Liquidity Rebalancer Factory: Identical tokens"
        );

        // sort based on uint values
        (address token0, address token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);

        require(
            getRebalancer[token0][token1] == address(0),
            "Liquidity Rebalancer Factory: Rebalancer exists"
        );

        bytes memory bytecode = abi.encodePacked(
            type(LiquidityRebalancer).creationCode,
            abi.encode(pool, token0, token1)
        );
        bytes32 salt = keccak256(abi.encodePacked(token0, token1));
        assembly {
            rebalancer := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(
            rebalancer != address(0),
            "Liquidity Rebalancer Factory: Failed to deploy"
        );

        getRebalancer[token0][token1] = rebalancer;
        getRebalancer[token1][token0] = rebalancer;
        allRebalancers.push(rebalancer);

        emit RebalancerCreated(
            token0,
            token1,
            rebalancer,
            allRebalancers.length - 1
        );
    }

    function getAllRebalancers() external view returns (address[] memory) {
        return allRebalancers;
    }

    function allRebalancersLength() external view returns (uint) {
        return allPairs.length;
    }
}
