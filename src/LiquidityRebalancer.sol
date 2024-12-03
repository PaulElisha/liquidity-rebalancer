// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILiquidityRebalancer.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@dragonswap/v2-periphery/contracts/libraries/LiquidityAmounts.sol";
import "@dragonswap/v2-periphery/contracts/libraries/PoolAddress.sol";
import "@dragonswap/v2-periphery/contracts/base/PeripheryImmutableState.sol";
import "@dragonswap/v2-periphery/contracts/base/LiquidityManagement.sol";
import "@dragonswap/v2-periphery/contracts/libraries/TickMath.sol";
import "@dragonswap/v2-core/contracts/interfaces/pool/IDragonswapV2Pool.sol";

contract LiquidityRebalancer is
    ILiquidityRebalancer,
    PeripheryImmutableState,
    LiquidityManagement
{
    address rebalancerFactory;
    address private immutable token0;
    address private immutable token1;
    IDragonswapV2Pool private immutable pool;

    constructor(
        address _token0,
        address _token1,
        address _pool,
        address _factory,
        address WETH9
    ) PeripheryImmutableState(_factory, WETH9) {
        rebalancerFactory = msg.sender;

        token0 = _token0;
        token1 = _token1;
        pool = IDragonswapV2Pool(
            PoolAddress.computeAddress(
                _factory,
                PoolAddress.getPoolKey(tokenA, tokenB, fee)
            )
        );
    }

    function rebalanceLiquidity(
        uint160 oldSqrtPriceAX96,
        uint160 oldSqrtPriceBX96,
        int24 tickLower,
        int24 tickUpper,
        uint160 newSqrtPriceAX96,
        uint160 newSqrtPriceBX96,
        uint128 liquidity
    ) external {
        AddLiquidityParams memory params = AddLiquidityParams({
            token0: token0,
            token1: token1,
            recipient: msg.sender,
            tickLower: tickLower,
            tickUpper: tickUpper,
            amount0Desired: amount0,
            amount1Desired: amount1,
            amount0Min: amount0,
            amount1Min: amount1
        });

        // get current SqrtPriceX96
        (uint160 sqrtPriceX96, , , , , , ) = pool.slot0();
        uint160 newSqrtRatioAX96 = TickMath.getSqrtRatioAtTick(
            params.tickLower
        );
        uint160 newSqrtRatioBX96 = TickMath.getSqrtRatioAtTick(
            params.tickUpper
        );

        uint128 newLiquidity = calculateOptimalLiquidity(
            sqrtPriceX96,
            newSqrtPriceAX96,
            newSqrtPriceBX96,
            amount0,
            amount1
        );

        require(
            IERC20(token0).transferFrom(msg.sender, address(this), amount0),
            "Liquidity Rebalancer: Transfer Failed"
        );

        require(
            IERC20(token1).transferFrom(msg.sender, address(this), amount1),
            "Liquidity Rebalancer: Transfer Failed"
        );

        IERC20(token0).approve(address(pool), amount0);
        IERC20(token1).approve(address(pool), amount1);

        (
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1,
            IDragonswapV2Pool pool
        ) = addLiquidity(params);
    }

    function calculateOptimalLiquidity(
        uint160 sqrtRatioX96,
        uint160 sqrtRationAX96,
        uint160 sqrtRationBX96,
        uint256 amount0,
        uint256 amount1
    ) returns (uint128 liquidity) {
        liquidity = LiquidityAmounts.getLiquidityAmounts(
            sqrtRatioX96,
            sqrtRationAX96,
            sqrtRationBX96,
            amount0,
            amount1
        );
    }

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            TransferHelper.safeTransfer(token, recipient, balanceToken);
        }
    }
}
