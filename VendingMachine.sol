//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract VendingMachine {
    mapping(string => mapping(address => uint)) public items;
    // A mapping from item to a mapping of addresses containing a certain number of the items
    mapping(string => uint) public prices; // mapping between itemm and its price

    // stocking up the store xD
    constructor() {
        items["Energy Drink"][address(this)] = 100;
        items["Cheese"][address(this)] = 40;
        items["Milk"][address(this)] = 50;

        prices["Energy Drink"] = 10;
        prices["Cheese"] = 25;
        prices["Milk"] = 7;
    }

    event Buy(string _item, uint _amount);
    function buy(string calldata _item, uint _amount) external payable returns (bool) {
        require(msg.value >= prices[_item] * _amount);
        items[_item][msg.sender] += _amount;
        items[_item][address(this)] -= _amount;

        emit Buy(_item, _amount);
        return true;
    }
    function stockUp(string calldata _item, uint _amount, uint _price) external {
        items[_item][address(this)] += _amount;
        
        if (prices[_item] == 0) {
            prices[_item] = _price;
        } else {
            prices[_item] = (prices[_item] + _price) / 2;
        }
    }
}
