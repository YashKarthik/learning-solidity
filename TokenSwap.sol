//SPDX-License-Identifier: MIT
pragma solidity ^0.8;
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract TokenSwap {
    IERC20 public token1;
    address public owner1;
    IERC20 public token2;
    address public owner2;
    uint public amount1;
    uint public amount2;

    constructor(
        address _token1,
        address _owner1,
        address _token2,
        address _owner2,
        uint _amount1,
        uint _amount2
    ) {
        token1 = IERC20(_token1);
        owner1 = _owner1;
        token2 = IERC20(_token2);
        owner2 = _owner2;
        amount1 = _amount1;
        amount2 = _amount2;
    }

    function swap() public {
        require(msg.sender == owner1 || msg.sender == owner2, "Unauthorized");
        require(token1.allowance(owner1, address(this)) >= amount1, "Token 1 allowance too low"); // checks if this contract is allowed to spend amount1 on owner1's behalf
        require(token2.allowance(owner2, address(this)) >= amount2, "Token 2 allowance too low"); // same thing

        _safeTransferFrom(token1, owner1, owner2, amount1);
        _safeTransferFrom(token2, owner2, owner1, amount2);
    }

    function _safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint _amount
    ) private {

        bool transfer = _token.transferFrom(_from, _to, _amount);
        require(transfer, "Swap failed");

    }
}
