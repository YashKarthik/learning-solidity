//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    event Transfer(address _from, address _to, uint _value);
    event Approval(address _owner, address _spender, uint256 _value);
}

contract Lmao is IERC20 {

    uint public totalSupply;
    mapping (address => uint) public balanceOf; // money is just a no. in a db.

    // Storing that the Owner (the first address) approves the spender to spend a certain number of our tokens.
    mapping (address => mapping(address => uint)) public allowance;

    string public name = "LmaoCoin";
    string public symbol = "LMAO";
    uint8 public decimal = 18; // 10^18 units = 1 LMAO

    function transfer(address _to, uint _amount) external returns (bool) {
        // the no. of tokens held is basically a no. in our `balanceOf` mapping.
        balanceOf[msg.sender] -= _amount;
        balanceOf[_to] += _amount;

        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint _amount) external returns (bool) {
        allowance[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);
        return true;

        // msg.sender is allowing the `_spender` to spend this much: `_amount`
    }

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount; // the sender has allowed msg.sender to call on their behalf. Will overflowa and fail if not.
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }

}
