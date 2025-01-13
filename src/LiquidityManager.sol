// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/Lib.sol";
import "./InitParameter.sol";

abstract contract LiquidityManager is Parameter {
    address public immutable factory;

    uint256 liquidityDeposited0;
    uint256 liquidityDeposited1;

    InitParameter public parameter;

    struct UserDeposit {
        address depositor;
        uint256 amount0;
        uint256 amount1;
    }

    mapping(address sender => mapping(address token0 => mapping(address token1 => UserDeposit)))
        public deposits;

    function initialize(InitParameter memory _parameter) external {
        require(msg.sender = factory);

        parameter = _parameter;
        parameter.token0 = _parameter.token0;
        parameter.token1 = _parameter.token1;
        parameter.pool = _parameter.pool;
        parameter.factory = _parameter.factory;
        parameter.initialized = _parameter.initialized;

        emit Initialized(
            _parameter.token0,
            _parameter.token1,
            _parameter.initialized
        );
    }

    function depositLiquidity(uint256 amount0, uint256 amount1) public {
        require(amount0 > 0 && amount1 > 0, DepositMustBeGreaterThanZero());
        require(amount0 > liquidityDeposited0 && amount1 > liquidityDeposited1);

        // Transfer tokens to the contract
        require(
            token0.transferFrom(msg.sender, address(this), amount0),
            "JIT: Transfer Failed"
        );
        require(
            token1.transferFrom(msg.sender, address(this), amount1),
            "JIT: Transfer Failed"
        );

        // Calculate shares to mint based on the proportional amount of both tokens
        uint256 depositShares = calculateShares(
            amount0,
            amount1,
            liquidityDeposited0,
            liquidityDeposited1
        );

        deposits[msg.sender][token0][token1] = UserDeposit({
            depositor: msg.sender,
            amount0: amount0,
            amount1: amount1
        });

        _update(amount0, amount1, liquidityDeposited0, liquidityDeposited1);
    }

    function _update(
        uint256 amount0,
        uint256 amount1,
        uint256 _liquidityDeposited0,
        uint256 _liquidityDeposited1
    ) internal {
        uint256 liquidityDepositedBefore0 = _liquidityDeposited0;
        uint256 liquidityDepositedBefore1 = _liquidityDeposited1;

        uint256 liquidityDepositedAfter0 = liquidityDepositedBefore0 + amount0;
        uint256 liquidityDepositedAfter1 = liquidityDepositedBefore1 + amount1;

        require(
            ((liquidityDepositedAfter0 - liquidityDepositedBefore0) ==
                amount0) ||
                ((liquidityDepositedAfter1 - liquidityDepositedBefore1) ==
                    amount1)
        );

        liquidityDeposited0 += amount0; // Update the total deposited amounts for both tokens
        liquidityDeposited1 += amount1;
    }

    function withdrawLiquidity(
        uint256 shareAmount,
        address withdrawTo
    ) external nonReentrant {
        require(shareAmount > 0, WithdrawalMustBeGreaterThanZero());
        require(balanceOf(msg.sender) >= shareAmount, InsufficientBalance());
        if (withdrawTo == address(0)) revert ZeroAddress();

        // Calculate amounts of token0 and token1 to withdraw
        uint256 token0Amount = (totalDepositedToken0 * shareAmount) /
            totalSupply();
        uint256 token1Amount = (totalDepositedToken1 * shareAmount) /
            totalSupply();

        // Burn the shares
        _burn(msg.sender, shareAmount);
        console2.log("Token amounts ::::", token0Amount, token1Amount);
        // Update total deposited amounts
        totalDepositedToken0 -= token0Amount;
        totalDepositedToken1 -= token1Amount;

        // Transfer tokens back to the user
        token0.transfer(withdrawTo, token0Amount);
        token1.transfer(withdrawTo, token1Amount);
    }

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            IERC20(token).transfer(token, recipient, balanceToken);
        }
    }

    function _getParameter()
        internal
        view
        returns (
            uint token0_,
            uint token1_,
            IDragonswapV2Pool pool,
            address _factory,
            bool initialized
        )
    {
        token0_ = parameter.token0;
        token1_ = parameter.token1;
        pool = parameter.pool;
        factory = parameter.factory;
        initialized = parameter.initialize;
    }

    function getUserDeposit(
        address sender
    ) public returns (UserDeposit memory) {
        address token0_;
        address token1_;

        (token0_, token1_, , , ) = _getParameter();

        return deposits[sender][token0_][token1_];
    }
}
