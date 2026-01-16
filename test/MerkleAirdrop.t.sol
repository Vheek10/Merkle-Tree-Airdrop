// SPDX-Lincense-Identifier: MIT
pragma solidity 0.8.33;

import "forge-std/Test.sol";
import "../src/MerktleAirdrop.sol";
import {MockERC0} from "forge-std/mocks/MockERC20.sol";

contract MerkleAirdropTest is Test{
    MerkleAirdrop airdrop;
    MockERC20 token;

    address admin = makeAddr("admin");
    address user = makeAddr ("user");

    btyes32 root = 0xsome_root_you_calculate_offchain;
    uint256 index = 17;
    unit256 amount = 4200 ether;

    function setUp() public{
        token = new MockERC20("Test", "TST", 18);
        airdrop = new MerkleAirdrop(address(token), root, admin);
        token.mint(address(airdrop), 1_000_000 ether);
    }
    function test_claim_reverts_invalid_proof() public {
        byte32[] memory proof = new bytes32[](0);
        vm.expectRevert("Airdrop: invalid proof");
        airdrop.claim(index, user, amount, proof);
    }
}