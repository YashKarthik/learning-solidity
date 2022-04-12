//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract MultiSig {

    mapping (address => uint8) private _owners;
    address[] private _ownersList;

    modifier isOwner() {
        require(_owners[msg.sender] == 1);
        _;
    }

    constructor() {
        _owners[msg.sender] = 1;
    }

    uint8 private constant CONFIRMATIONS = 2;
    uint private _transactionId = 0;

    event Transfered(address to, uint amount);
    event Received(address from, uint amount);
    event Signed(address who, address signee);
    event TxCreated(address to, uint amount);
    event TxFailed(address to, uint amount);

    // Tx object
    struct Transaction {
        address to;
        uint amount;
        uint8 sigCount;
        bool executed;
    }
    
    // to store who signed each tx
    mapping (uint => mapping (address => uint8)) private _signatures;

    // mapping of txId and Tx
    mapping (uint => Transaction) public _transactions;
    // pending txs
    Transaction[] private _pendingTxs;

    function createTx(address _to, uint _amount) public isOwner {
        require(address(this).balance >= _amount);
        require(address(0) != _to);

        uint _txId = _transactionId++;
        Transaction memory _transaction = Transaction(_to, _amount, 0, false);

        _transactions[_txId] = _transaction;
        emit TxCreated(_to, _amount);
    }

    function signTx(uint _txId) public isOwner {
        require(_signatures[_txId][msg.sender] == 0);
        _transactions[_txId].sigCount++;
        _signatures[_txId][msg.sender] = 1;

        emit Signed(_transactions[_txId].to, msg.sender);
        executeTx(_txId);
    }

    function executeTx(uint _txId) public isOwner {
        Transaction memory _tx = _transactions[_txId];
        require(_tx.executed == false);
        require(_tx.sigCount >= CONFIRMATIONS);
        (bool success) = payable(_tx.to).send(_tx.amount);

        if (success == true) {
            _tx.executed = true;
            emit Transfered(_tx.to, _tx.amount);
        }
        else {
            emit TxFailed(_tx.to, _tx.amount);
        }
    }

    function revokeTx(uint _txId) public isOwner {
        require(_signatures[_txId][msg.sender] == 1);
        _transactions[_txId].sigCount--;
        _signatures[_txId][msg.sender] = 0;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    struct Operation {
        address _new;
        uint8 sigCount;
        bool executed;
    }

    event AddOwner(address _new, bool added);
    event SignNewOwner(address _new, address signee);

    mapping(address => Operation) public _addOwner;
    mapping(address => mapping(address => uint8)) private _addSig;

    function InitAddOwner(address _newAddr) public isOwner {
        require(_owners[_newAddr] != 1);
        Operation memory newUser = Operation(_newAddr, 0, false);
        _addOwner[_newAddr] = newUser;

        emit AddOwner(_newAddr, false);
    }

    function signAddOwner(address _newAddr) public isOwner {
        require(_addSig[_newAddr][msg.sender] == 0);
        require(_newAddr != address(0));

        _addSig[_newAddr][msg.sender] = 1;
        _addOwner[_newAddr].sigCount++;

        emit SignNewOwner(_newAddr, msg.sender);
        addOwner(_newAddr);
    }

    function addOwner(address _newAddr) public isOwner {
        require(_owners[_newAddr] != 1);
        require(_ownersList.length > CONFIRMATIONS ? _addOwner[_newAddr].sigCount >= CONFIRMATIONS : _addOwner[_newAddr].sigCount > 0);

        _addOwner[_newAddr].executed = true;
        _ownersList.push(_newAddr);
        _owners[_newAddr] = 1;
    }
    
}
