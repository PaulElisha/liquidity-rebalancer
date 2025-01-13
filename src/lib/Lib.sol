// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Lib {
    function calculateShares(
        uint256 amount0,
        uint256 amount1,
        uint256 totalDepositedToken0,
        uint256 totalDepositedToken1
    ) internal view returns (uint256) {
        // if (totalSupply() == 0) {
        //     // Initial liquidity, return the geometric mean of the two amounts
        //     return sqrt(amount0 * amount1);
        // } else {
        //     // Calculate shares proportional to both token0 and token1
        //     uint256 totalLiquidity = totalDepositedToken0 +
        //         totalDepositedToken1;
        //     uint256 totalDeposit = amount0 + amount1;
        //     return (totalDeposit * totalSupply()) / totalLiquidity;
        // }
    }

    function getPriceThresholds(
        uint160 sqrtPrice,
        uint16 tickSpacing,
        uint256 priceAdjustmentFactor // Adjustment factor for price range, e.g., 0.01 for +/- 1%
    ) external pure returns (uint160 lowerThreshold, uint160 upperThreshold) {
        uint256 adjustment = (sqrtPrice * priceAdjustmentFactor) / 100;
        lowerThreshold = uint160(sqrtPrice - adjustment);
        upperThreshold = uint160(sqrtPrice + adjustment);

        require(lowerThreshold < upperThreshold, "Invalid price range");

        lowerThreshold = alignToTick(lowerThreshold, tickSpacing);
        upperThreshold = alignToTick(upperThreshold, tickSpacing);

        return (lowerThreshold, upperThreshold);
    }

    function alignToTick(
        uint160 price,
        uint16 tickSpacing
    ) internal pure returns (uint160 alignedPrice) {
        int24 tick = int24(price / tickSpacing);
        alignedPrice = uint160(tick * tickSpacing);
        return alignedPrice;
    }

    function calculateNextTicks(
        uint160 currentPrice,
        uint24 tickSpacing
    ) private pure returns (int24 lowerTick, int24 upperTick) {
        int24 currentTick = TickMath.getTickAtSqrtPrice(currentPrice);

        lowerTick = (currentTick / int24(tickSpacing)) * int24(tickSpacing);

        upperTick = lowerTick + int24(tickSpacing);

        require(
            upperTick > lowerTick,
            "Upper tick must be greater than lower tick"
        );
    }

    function getSqrtPriceFromCurrentPrice(
        uint256 currentPrice
    ) private pure returns (uint160 sqrtPrice) {
        uint256 sqrtPriceInWei = FullMath.mulDiv(
            currentPrice,
            1 << 96,
            1 << 96
        );

        require(sqrtPriceInWei > 0, "Price must be greater than zero");
        require(sqrtPriceInWei < type(uint160).max, "sqrtPrice is too large");

        return uint160(sqrtPriceInWei);
    }

    function calculateOptimalLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRationAX96,
        uint160 sqrtRationBX96,
        uint256 amount0,
        uint256 amount1
    ) private returns (uint128 liquidityDelta) {
        liquidityDelta = LiquidityAmounts.getLiquidityAmounts(
            sqrtRatioX96,
            sqrtRationAX96,
            sqrtRationBX96,
            amount0,
            amount1
        );
    }
}
