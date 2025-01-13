// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib.sol";
import "./LiquidityManager.sol";
import "./interfaces/ILiquidityRebalancer.sol";
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

contract LiquidityRebalancer is ILiquidityRebalancer {
    using Lib for uint160;
    using Lib for uint256;

    LiquidityManager liquidityManager;

    constructor() {
        factory = msg.sender;
        liquidityManager = new LiquidityManager();
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

        (uint256 amount0_, uint256 amount1_) = pool_.burn(
            tickLower,
            tickUpper,
            liquidity
        );

        pool_.collect(
            msg.sender,
            tickLower,
            tickUpper,
            uint128(amount0_),
            uint128(amount1_)
        );
    }

    function addLiquidity(
        int24 tickSpacing,
        uint256 priceAdjustment,
        uint256 amount0,
        uint256 amount1,
    ) public {
        require(amount0 > 0 && amount1 > 0, "Invalid token amounts");

        liquidityManager.depositLiquidity(amount0, amount1);

        (
            address token0_,
            address token1_,
            IDragonPool pool_,
            ,
            ,

        ) = _getParameter();

        (int24 newTickLower, int24 newTickUpper) = check(
            tickSpacing,
            priceAdjustment
        );

        require(newTickLower < newTickUpper, "Invalid tick range");

        (uint160 sqrtPriceX96, , , , , , ) = pool_.slot0;

        uint160 newSqrtRatioAX96 = TickMath.getSqrtRatioAtTick(newTickLower);
        uint160 newSqrtRatioBX96 = TickMath.getSqrtRatioAtTick(newTickUpper);

        uint128 liquidityDelta = sqrtPriceX96.calculateOptimalLiquidity(
            newSqrtPriceAX96,
            newSqrtPriceBX96,
            amount0,
            amount1
        );

        require(liquidityDelta > 0, "Insufficient liquidity");

        IERC20(token0_).approve(address(pool_), amount0);
        IERC20(token1_).approve(address(pool_), amount1);

        pool_.mint(msg.sender, newTickLower, newTickUpper, liquidityDelta, "");
    }

    function check(
        int24 tickStep,
        uint256 priceAdjustmentFactor
    ) external returns (int24 newTickLower, int24 newTickUpper) {
        uint256 currentPrice = getLatestPrice();
        uint160 currentSqrtPrice = currentPrice.getSqrtPriceFromCurrentPrice();

        (
            uint160 priceLowerThreshold,
            uint160 priceUpperThreshold
        ) = currentSqrtPrice.getPriceThresholds(
                tickStep,
                priceAdjustmentFactor
            );

        require(
            currentSqrtPrice <= priceLowerThreshold ||
                currentSqrtPrice >= priceUpperThreshold,
            "Price within acceptable range"
        );

        (newTickLower, newTickUpper) = currentSqrtPrice.calculateNextTicks(
            tickStep
        );
    }

    function getLatestPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        require(price > 0, "Price is zero");
        return uint256(price);
    }

    function rebalanceLiquidity(
        int24 oldTickLower,
        int24 oldTickUpper,
        uint128 liquidity,
        int24 tickSpacing,
        uint256 priceAdjustmentFactor
    ) external {
        (uint256 amount0, uint256 amount1) = withdrawLiquidity(
            oldTickLower,
            oldTickUpper,
            liquidity
        );

        (int24 newTickLower, int24 newTickUpper) = check(tickSpacing);

        addLiquidity(newTickLower, newTickUpper, amount0, amount1);
    }


}
