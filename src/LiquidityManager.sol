// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/Lib.sol";
import "./InitParameter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LiquidityManager is ReentrancyGuard {
    using Lib for uint256;
    using SafeERC20 for IERC20;

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

    event Initialized(address token0, address token1, bool init);

    function initialize(InitParameter memory _parameter) external {
        require(_parameter.factory == msg.sender);

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
        (address token0, address token1, , , ) = _getParameter();

        require(
            amount0 > 0 && amount1 > 0,
            "Amount should be greater than zero"
        );
        require(amount0 > liquidityDeposited0 && amount1 > liquidityDeposited1);

        // Transfer tokens to the contract

        IERC20(token0).safeTransferFrom(msg.sender, address(this), amount0);

        IERC20(token1).safeTransferFrom(msg.sender, address(this), amount1);

        // Calculate shares to mint based on the proportional amount of both tokens
        uint256 depositShares = amount0.calculateShares(
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
        // require(shareAmount > 0, WithdrawalMustBeGreaterThanZero());
        // require(balanceOf(msg.sender) >= shareAmount, InsufficientBalance());
        // if (withdrawTo == address(0)) revert ZeroAddress();
        // // Calculate amounts of token0 and token1 to withdraw
        // uint256 token0Amount = (totalDepositedToken0 * shareAmount) /
        //     totalSupply();
        // uint256 token1Amount = (totalDepositedToken1 * shareAmount) /
        //     totalSupply();
        // // Burn the shares
        // _burn(msg.sender, shareAmount);
        // console2.log("Token amounts ::::", token0Amount, token1Amount);
        // // Update total deposited amounts
        // totalDepositedToken0 -= token0Amount;
        // totalDepositedToken1 -= token1Amount;
        // // Transfer tokens back to the user
        // token0.transfer(withdrawTo, token0Amount);
        // token1.transfer(withdrawTo, token1Amount);
    }

    function sweepToken(
        address token,
        uint256 amountMinimum,
        address recipient
    ) public {
        uint256 balanceToken = IERC20(token).balanceOf(address(this));
        require(balanceToken >= amountMinimum, "Insufficient token");

        if (balanceToken > 0) {
            IERC20(token).transfer(recipient, balanceToken);
        }
    }

    function _getParameter()
        internal
        view
        returns (
            address token0_,
            address token1_,
            address pool,
            address _factory,
            bool initialized
        )
    {
        token0_ = parameter.token0;
        token1_ = parameter.token1;
        pool = parameter.pool;
        _factory = parameter.factory;
        initialized = parameter.initialized;
    }

    function getUserDeposit(
        address sender
    ) public view returns (UserDeposit memory) {
        address token0_;
        address token1_;

        (token0_, token1_, , , ) = _getParameter();

        return deposits[sender][token0_][token1_];
    }
}
