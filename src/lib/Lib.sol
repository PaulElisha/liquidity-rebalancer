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
}
