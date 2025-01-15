// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILiquidityRebalancer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@dragonswap/v2-periphery/contracts/libraries/LiquidityAmounts.sol";
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

    address token0;
    address token1;
    address factory;
    address priceFeed;
    IDragonswapV2Pool public pool;

    constructor() {
        factory = msg.sender;

    }

    function initialize(address _pool, address token0_, address token1_) public {
        if(uint160(token0_) < uint160(token1_)) {

        pool = IDragonswapV2Pool(_pool);
        token0 = token0_;
        token1 = token1_;
        } else {
       pool = IDragonswapV2Pool(_pool);
        token0 = token1_;
        token1 = token0_;
        }
    }

    function withdrawLiquidity(
        int24 tickLower,
        int24 tickUpper,
        uint128 liquidity
    ) private returns(uint256 amount0, uint256 amount1) {
        require(tickLower < tickUpper, "Invalid tick range");

        (uint160 sqrtPriceX96, int24 tick, , , , , ) = pool.slot0;

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

        pool.collect(
            address(msg.sender),
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
        uint256 amount1,
    ) private {
        require(tickLower < tickUpper, "Invalid tick range");
        require(amount0 > 0 && amount1 > 0, "Invalid token amounts");

            address token0_ = token0;
            address token1_ = token1;

        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0;

        uint160 newSqrtRatioAX96 = TickMath.getSqrtRatioAtTick(tickLower);
        uint160 newSqrtRatioBX96 = TickMath.getSqrtRatioAtTick(tickUpper);

        uint128 liquidityDelta = sqrtPriceX96.calculateOptimalLiquidity(
            newSqrtPriceAX96,
            newSqrtPriceBX96,
            amount0,
            amount1
        );

        require(liquidityDelta > 0, "Insufficient liquidity");

        IERC20(token0_).approve(address(pool), amount0);
        IERC20(token1_).approve(address(pool), amount1);

        pool.mint(msg.sender, tickLower, tickUpper, liquidityDelta, hex"");
    }

    function check(
        int24 tickStep,
        uint256 priceAdjustmentFactor
    ) private returns (int24 newTickLower, int24 newTickUpper) {
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

    function getLatestPrice() private view returns (uint256) {
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
        (uint256 amount0, uint256 amount1) =  withdrawLiquidity(
            oldTickLower,
            oldTickUpper,
            liquidity
        );

        (int24 newTickLower, int24 newTickUpper) = check(tickSpacing, priceAdjustmentFactor);


        addLiquidity(newTickLower, newTickUpper, amount0, amount1);
    }


}
