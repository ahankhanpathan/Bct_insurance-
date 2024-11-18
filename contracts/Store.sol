// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Store {
    address public admin;

    struct Object {
        uint price;
        uint cashBackPercent;
        bool isAvailable;
    }

    mapping(string => Object) public storeItems;
    mapping(address => uint) public customerBalances;
    mapping(address => uint) public reputationScores;
    mapping(address => bool) public isEligible;
    uint public subsidyFunds;
    bool private initialized; // To check if initialized

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    

    // function initialize(uint initialFund) public {
    //     require(!initialized, "Already initialized");
    //     admin = msg.sender;
    //     subsidyFunds = initialFund;

    //     storeItems["SolarPanel"] = Object(1000, 10, true);  
    //     storeItems["OlaEV"] = Object(500, 5, true);         
    //     storeItems["LPG-Gas"] = Object(100, 3, true);       

    //     initialized = true;
    // }

    function initialize(uint initialFund) public {
        require(!initialized, "Already initialized");
        admin = msg.sender;
        require(msg.sender == admin, "Only admin can initialize");
        require(subsidyFunds == 0, "Already initialized");
        subsidyFunds = initialFund;
    }


    function deposit() external payable {
        require(msg.value > 0, "Deposit must be greater than zero");
        customerBalances[msg.sender] += msg.value;
    }

    function buyObject(string memory itemName) public {
        require(msg.sender != admin, "Admin cannot buy items");
        require(subsidyFunds > 0, "Subsidy over");
        require(isEligible[msg.sender], "Customer is not eligible to buy");

        Object memory item = storeItems[itemName];
        require(item.isAvailable, "Object not in store");
        require(customerBalances[msg.sender] >= item.price, "Insufficient balance");

        uint originalBalance = customerBalances[msg.sender];
        customerBalances[msg.sender] -= item.price;
        assert(customerBalances[msg.sender] == originalBalance - item.price);

        if (subsidyFunds > 0) {
            uint cashBack = (item.price * item.cashBackPercent) / 100;
            if (cashBack > subsidyFunds) {
                cashBack = subsidyFunds; 
            }
            customerBalances[msg.sender] += cashBack;
            subsidyFunds -= cashBack;
        }
    }

    function setReputationScore(address customer, uint score) public {
        reputationScores[customer] = score;
        isEligible[customer] = score >= 50;
    }

    function getCustomerBalance() public view returns (uint) {
        return customerBalances[msg.sender];
    }

    function addObjectToStore(string memory itemName, uint price, uint cashBackPercent) public onlyAdmin {
        storeItems[itemName] = Object(price, cashBackPercent, true);
    }

    function updateSubsidyFund(uint newFund) public onlyAdmin {
        subsidyFunds = newFund;
    }

    function withdraw(uint amount) public {
        require(customerBalances[msg.sender] >= amount, "Insufficient balance");
        customerBalances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function checkEligibility(address customer) public view returns (bool) {
        return isEligible[customer];
    }

    function getsubsidyFunds() public view returns (uint) {
        return subsidyFunds;
    }
}