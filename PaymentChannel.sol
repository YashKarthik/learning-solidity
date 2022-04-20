//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/utils/cryptography/ECDSA.sol";
import "github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/security/ReentrancyGuard.sol";

contract PaymentChannel {
    using ECDSA for bytes32;

    /*
            1. Alice funds the contract with the total she wants to send.
            2. Signs off-chain messages that allow Bob to withdraw some amount
            3. Bob submits the latest message to close the contract and withdraw the funds, the 
                remaining funds are send back to alice.

            4. Messages must contain the conract address, amount signed by the sender.
            5. channel can be closed after some time if bob doesn't withdraw funds.

            sig = sign(m, sk)
            pk = verify(m, sig)
    
    */

    address payable sender;
    address payable receiver;
    uint public expiresAt;

    constructor (address _receiver, uint _duration) payable {
        sender = payable(msg.sender);
        receiver = payable(_receiver);
        expiresAt = block.timestamp + _duration;
    }

    function hashMessage(uint _amount) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _amount));
    }

    function signHash(uint _amount) public view returns (bytes32) {
        return hashMessage(_amount).toEthSignedMessageHash();
    }

    function verify(uint _amount, bytes memory _sig) public view returns (bool) {
        return signHash(_amount).recover(_sig) == sender;
    }

    function withdrawAndClose(uint _amount, bytes memory _sig) public {
        require(msg.sender == receiver, "You are not the receiver");
        require(verify(_amount, _sig) == true, "Invalid Signature");

        (bool success,) = (msg.sender).call{value: _amount}("");
        require(success, "Withdrawl failed");
        selfdestruct(sender);
    }

    function cancelChannel() public {
        require(msg.sender == sender, "Not owner");
        require(block.timestamp > expiresAt, "Not yet expired");

        selfdestruct(payable(msg.sender));   
    }
    
    function extendChannel(uint _extraDuration) public {
        expiresAt += _extraDuration * 1 hours;
    }

}
