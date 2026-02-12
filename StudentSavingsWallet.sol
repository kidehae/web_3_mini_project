pragma solidity ^0.8.18;

contract StudentSavingsWallet {
    // State variables
    mapping(address => uint256) public balances;
    address public owner;
    uint256 public minDeposit;
    uint256 public lockTime;
    mapping(address => uint256) public lastWithdrawalTime;
    
    // Transaction structure
    struct Transaction {
        address user;
        uint256 amount;
        uint256 timestamp;
        string txType;
    }
    
    Transaction[] public transactions;
    event Deposited(address indexed user, uint256 amount, uint256 timestamp);
    event Withdrawn(address indexed user, uint256 amount, uint256 timestamp);
    event MinDepositChanged(uint256 oldMin, uint256 newMin);
    
    // Constructor
    constructor(uint256 _minDeposit, uint256 _lockTime) {
        owner = msg.sender;
        minDeposit = _minDeposit;
        lockTime = _lockTime;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    // Deposit function
    function deposit() public payable {
        require(msg.value >= minDeposit, "Deposit amount too low");
        
        balances[msg.sender] += msg.value;
        
        transactions.push(Transaction({
            user: msg.sender,
            amount: msg.value,
            timestamp: block.timestamp,
            txType: "deposit"
        }));
        
        emit Deposited(msg.sender, msg.value, block.timestamp);
    }
    
    // Withdraw function
    function withdraw(uint256 _amount) public {
        require(balances[msg.sender] >= _amount, "Insufficient balance");
        require(block.timestamp >= lastWithdrawalTime[msg.sender] + lockTime, "Withdrawal too soon");
        
        balances[msg.sender] -= _amount;
        lastWithdrawalTime[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(_amount);
        
        transactions.push(Transaction({
            user: msg.sender,
            amount: _amount,
            timestamp: block.timestamp,
            txType: "withdraw"
        }));
        
        emit Withdrawn(msg.sender, _amount, block.timestamp);
    }
    
    // View functions
    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function getTransactionHistory() public view returns (Transaction[] memory) {
        uint256 count = 0;
        for(uint i = 0; i < transactions.length; i++) {
            if(transactions[i].user == msg.sender) {
                count++;
            }
        }
        
        Transaction[] memory userTransactions = new Transaction[](count);
        uint256 index = 0;
        
        for(uint i = 0; i < transactions.length; i++) {
            if(transactions[i].user == msg.sender) {
                userTransactions[index] = transactions[i];
                index++;
            }
        }
        
        return userTransactions;
    }
    
    // Owner functions
    function setMinDeposit(uint256 _newMin) public onlyOwner {
        emit MinDepositChanged(minDeposit, _newMin);
        minDeposit = _newMin;
    }
    
    function setLockTime(uint256 _newLockTime) public onlyOwner {
        lockTime = _newLockTime;
    }
}