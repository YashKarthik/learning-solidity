//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {

    address[] public owners;
    mapping (address => bool) public isOwner;
    uint public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        mapping (address => bool) isConfirmed;
        uint confirmations;
    }

    Transaction[] public transactions;

    event Deposit(address indexed sender, uint amount, uint balance);

    event SubmitTransaction(
        address indexed owner,
        uint indexed txId,
        address indexed to,
        uint value,
        bytes data
    );

    event ConfirmTransaction(address indexed owner, uint indexed txId);
    event RevokeConfirmation(address indexed owner, uint indexed txId);
    event ExecuteTransaction(address indexed owner, uint indexed txId);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "Tx does not exist");
        _;
    }

    modifier notExecuted(uint _txId) {
        require(!transactions[_txId].executed, "Tx already executed");
        _;
    }

    modifier notConfirmed(uint _txId) {
        require(!transactions[_txId].isConfirmed[msg.sender], "Already confirmed");
        _;
    }

    constructor(address[] memory _owners, uint _numConfirmationsRequired) {
        
        require(_owners.length > 0, "Owners required");
        require(_numConfirmationsRequired <= _owners.length && _numConfirmationsRequired > 0, 
            "Invalid number of confirmations");

        for (uint i=0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "Invalid owner");
            require(!isOwner[_owners[i]], "Owner already exists");

            isOwner[_owners[i]] == true;
            owners.push(_owners[i]);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) 
        public
        onlyOwner
    {
        uint txId = transactions.length;

        Transaction storage t = transactions[transactions.length];
        t.to = _to;
        t.value = _value;
        t.data = _data;
        t.executed = false;
        t.confirmations = 0;

        emit SubmitTransaction(msg.sender, txId, _to, _value, _data);
    }


    function confirmTransaction(uint _txId) 
        public
        onlyOwner 
        txExists(_txId)
        notExecuted(_txId)
        notConfirmed(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.isConfirmed[msg.sender] = true;
        transaction.confirmations++;

        emit ConfirmTransaction(msg.sender, _txId);
    }

    function executeTransaction(uint _txId) 
        public
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        require(transaction.confirmations >= numConfirmationsRequired,
            "Insuffecient confirmations");

        transaction.executed = true;
        (bool success,) = transaction.to.call{value: transaction.value}(abi.encodeWithSignature(string(transaction.data)));
        require(success, "Tx failed");

        emit ExecuteTransaction(msg.sender, _txId);
    }
    function revokeConfirmation(uint _txId) 
        public
        onlyOwner
        txExists(_txId)
    {
        Transaction storage transaction = transactions[_txId];
        transaction.isConfirmed[msg.sender] = false;
        transaction.confirmations--;

        emit RevokeConfirmation(msg.sender, _txId);
    }

    receive() payable external {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }
}
