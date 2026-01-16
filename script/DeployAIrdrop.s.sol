// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import "forge-std/Script.sol";
import "../src/MerkleAirdrop.sol";

contract DeployAirdrop is Script {
    function run() external {
        vm.startBroadcast();

        address token = 0x...;          // your ERC20
        bytes32 root  = 0x...;          // computed off-chain
        address owner = msg.sender;

        new MerkleAirdrop(token, root, owner);

        vm.stopBroadcast();
    }
}