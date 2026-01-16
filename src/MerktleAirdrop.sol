//SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title MerkleAIrdrop
/// @notice Gas-efficient ERC20 airdrop using Merkle tree proofs
/// @custom:security non-reentrant claim not needed bacause we use bitmap

contract MerkleAirdrop is Ownable{
    IERC20 public immutable token;
    byte32 public immutable merkleRoot;

    // Bitmap: 256 claim per uint256 slot -> very gas-efficient
    mapping(uint256 => uint256) private claimedBitmap;

    event Claimed(ddress indexed claimant, uint256 indexed index, uint256 amount);

    constructor(
        address _token,
        bytes32 _merkleRoot,
        address initialOwner
    ) Ownable (initialOwner){
        token = IERC20 (_token);
        merkleRoot = _merkleRoot;
    }

    /// @notice Claim your allocated tokens
    /// @param index Your position in the original Merkle list (for bitmap)
    /// @param account Recipient address (isially msg.sender)
    /// @param amount Token amount for this leaf is entitled to
    /// @param proof Merkle proof siblings
    function claim(
        uint256 index,
        address account,
        uint256 amount,
        bytes32[] calldata proof
    )external {
        require(amount > 0, "Airdrop:zero amount");

        // Prevent double-claim
        require(!_isClaimed(index), "Airdrop already claimed");

        //Leaf = keccak256(keccak256(abi.encode(account, amount))) <- double hash
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));

        require(
            MerkleProof.verify(proof, merkleRoot, leaf),
            "Airdrop: invalid proof"
        );

        _setClaimed(index);

        bool success = token.transfer(account, amount);
        require(success, "Airdrop: token transfer failed");

        emit Claimed(account, index, amount);
    }

    //---------------BitMap helpers---------------------
    function _isClaimed(unit256 index) internal {
        uint256 row = index >> 8;
        uint256 bit = index & 0xff;
        claimedBitMap[row] | (1 << bit);    
    }
    //---------------Admin / Rescue -------------------

    /// @notice Recover tokens accidentally sent to contract (not the airdrop token)
    function rescueERC20 (address tokenToRescue, uint256 amount, address to) external onlyOwner{
        require(tokenToRescue != address(token), "Cannot rescue airdrop token");
        IERC20(tokenToRescue).transfer(to, amount);
    }

    /// @notice Withdraw remaining airdrop tokens after campaign ends
     function withdrawRemaining(uint256 amount, address to) external onlyOwner{
        token.transfer(to, amount);
     }

     /// @notice Check if a given index has been claimed
     function isClaimed(uint256 index) external view returns (bool){
        return _isClaimed(index);
     }
}