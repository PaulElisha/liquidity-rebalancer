// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILiquidityRebalancer.sol";
import "./LiquidityManager.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@dragonswap/v2-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@dragonswap/v2-periphery/contracts/base/LiquidityManagement.sol";
import "@dragonswap/v2-core/contracts/libraries/TickMath.sol";
import "@dragonswap/v2-core/contracts/interfaces/IDragonswapV2Pool.sol";

// initialize
// set time and price logic
// deposit
// calculate shares
// withdraw
// sell shares
// require optimal amount1 provided
// get optimal liquidity
// time-based mechanism to add or remove liquidity
//

contract LiquidityRebalancer is LiquidityManager, ILiquidityRebalancer {
    constructor() {
        factory = msg.sender;
    }

    function withdrawLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) public returns (uint256 amount0, uint256 amount1) {
        require(tickLower < tickUpper, "Invalid tick range");

        (
            address token0_,
            address token1_,
            IDragonswapV2Pool pool_,
            ,
            ,

        ) = _getParameter();

        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool_.slot0;

        uint160 oldSqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 oldSqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        require(
            (tickLower <= currentTick && currentTick < tickUpper),
            "Ticks out of range"
        );

        (amount0, amount1) = LiquidityAmounts.getAmountsForLiquidity(
            sqrtPriceX96,
            sqrtRatioAX96,
            sqrtRatioBX96,
            liquidity
        );

        (uint256 amount0_, uint256 amount1_) = pool.burn(
            tickLower,
            tickUpper,
            liquidity
        );

        require(amount0 == amount0_ && amount1 == amount1_);

        pool.collect(
            msg.sender,
            tickLower,
            tickUpper,
            uint128(amount0_),
            uint128(amount1_)
        );
    }

    function addLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint256 amount0,
        uint256 amount1
    ) public {
        require(tickLower < tickUpper, "Invalid tick range");
        require(amount0 > 0 && amount1 > 0, "Invalid token amounts");

        depositLiquidity(amount0, amount1);

        (
            address token0_,
            address token1_,
            IDragonPool pool_,
            ,
            ,

        ) = _getParameter();

        (uint160 sqrtPriceX96, , , , , , ) = pool_.slot0;

        uint160 newSqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 newSqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        uint128 optimalLiquidity = calculateOptimalLiquidity(
            sqrtPriceX96,
            newSqrtPriceAX96,
            newSqrtPriceBX96,
            amount0,
            amount1
        );

        require(optimalLiquidity > 0, "Insufficient liquidity");

        IERC20(token0).approve(address(pool), amount0);
        IERC20(token1).approve(address(pool), amount1);

        pool.mint(msg.sender, tickLower, tickUpper, optimalLiquidity, "");
    }

    function rebalanceLiquidity(
        int24 oldTickLower,
        int24 oldTickUpper,
        uint128 liquidity,
        int24 tickLower,
        int24 tickUpper
    ) external {
        (uint256 amount0, uint256 amount1) = withdrawLiquidity(
            oldTickLower,
            oldTickUpper,
            liquidity
        );

        addLiquidity(tickLower, tickUpper, amount0, amount1);
    }

    function calculateOptimalLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRationAX96,
        uint160 sqrtRationBX96,
        uint256 amount0,
        uint256 amount1
    ) private returns (uint128 liquidity) {
        liquidity = LiquidityAmounts.getLiquidityAmounts(
            sqrtRatioX96,
            sqrtRationAX96,
            sqrtRationBX96,
            amount0,
            amount1
        );
    }
}
