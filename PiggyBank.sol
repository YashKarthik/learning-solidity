//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Piggy {
  address payable owner;
  uint public releaseTimestamp;

  constructor() payable {
    owner = payable(msg.sender);
  }
    
  event Locked(uint _releaseTimestamp, uint _lockAmt);

  function lockIn(uint _lockPeriod) public payable {
    releaseTimestamp = block.timestamp + (_lockPeriod * 60);
    emit Locked(releaseTimestamp, msg.value);
  }

  event Withdraw(uint _releaseTimestamp, uint _actualReleaseTimestamp, uint _amount);
    
  function breakPiggy() public {
    require(msg.sender == owner, "msg.sender not owner");
    require(block.timestamp >= releaseTimestamp, "Lock in period not complete");

    uint value = address(this).balance;
    emit Withdraw(releaseTimestamp, block.timestamp, value);
    selfdestruct(payable(msg.sender));
  }
}
