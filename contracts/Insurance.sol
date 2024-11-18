// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract InsuranceClaim {
    enum ClaimStatus { Pending, Approved, Rejected }
    enum PolicyStatus { Active, Expired, Canceled }

    address private admin; // Admin address

    // Insurance fee (example 1 ETH)
    uint256 public insuranceFee = 1 ether; // 1 ETH

    // Authorized entities
    mapping(address => bool) private authorizedApprovers;
    mapping(address => bool) private hospitals;
    mapping(address => bool) private carDealerships;

    struct Policy {
        uint256 policyId;
        uint256 coverageAmount;
        uint256 premium;
        uint256 expirationDate;
        PolicyStatus status;
        uint256 claimCount;
        uint256 claimLimit;
    }

    struct Claim {
        uint256 claimAmount;
        ClaimStatus status;
        string reason;
    }

    // Mappings
    mapping(address => Policy[]) public userPolicies; // User to policies mapping
    mapping(address => mapping(uint256 => Claim[])) public userClaims; // User's policy ID to claims mapping

    uint256 public policyCounter; // Global counter for policies

    // Events
    event PolicyCreated(address indexed policyHolder, uint256 policyId);
    event ClaimSubmitted(address indexed policyHolder, uint256 policyId, uint256 claimAmount);
    event ClaimApproved(address indexed approver, address indexed policyHolder, uint256 policyId, uint256 claimAmount);
    event ClaimRejected(address indexed approver, address indexed policyHolder, uint256 policyId, uint256 claimAmount);
    event HospitalAdded(address hospital);
    event CarDealershipAdded(address carDealership);
    event ApproverAdded(address approver);

    constructor() {
        admin = msg.sender; // The deployer becomes the admin
        policyCounter = 0; // Initialize policy counter
    }

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyAuthorizedApprovers() {
        require(
            authorizedApprovers[msg.sender] || hospitals[msg.sender] || carDealerships[msg.sender],
            "Not an authorized approver"
        );
        _;
    }

    // Getter for insurance fee
    function getInsuranceFee() public view returns (uint256) {
        return insuranceFee;
    }

    // Admin functions to add authorized entities
    function addHospital(address hospital) public onlyAdmin {
        require(!hospitals[hospital], "Hospital already added");
        hospitals[hospital] = true;
        emit HospitalAdded(hospital);
    }

    function addCarDealership(address carDealership) public onlyAdmin {
        require(!carDealerships[carDealership], "Car dealership already added");
        carDealerships[carDealership] = true;
        emit CarDealershipAdded(carDealership);
    }

    function addApprover(address approver) public onlyAdmin {
        require(!authorizedApprovers[approver], "Approver already added");
        authorizedApprovers[approver] = true;
        emit ApproverAdded(approver);
    }

    // Create a new policy for a specified user
    function createPolicy(
        address policyHolder,
        uint256 coverageAmount,
        uint256 premium,
        uint256 duration,
        uint256 claimLimit
    ) public payable {
        require(msg.value >= premium, "Insufficient premium amount");

        Policy memory newPolicy = Policy({
            policyId: policyCounter,
            coverageAmount: coverageAmount,
            premium: premium,
            expirationDate: block.timestamp + duration,
            status: PolicyStatus.Active,
            claimCount: 0,
            claimLimit: claimLimit
        });

        userPolicies[policyHolder].push(newPolicy);

        emit PolicyCreated(policyHolder, policyCounter);
        policyCounter++;
    }

    // Submit a claim for a specific policy
    function submitClaim(uint256 policyId, uint256 claimAmount, string memory reason) public {
    Policy[] storage policies = userPolicies[msg.sender];

    require(policyId < policies.length, "Policy not found");
    Policy storage policy = policies[policyId];
    require(policy.status == PolicyStatus.Active, "Policy is not active");
    require(block.timestamp < policy.expirationDate, "Policy expired");
    require(policy.claimCount < policy.claimLimit, "Claim limit reached");
    require(claimAmount <= policy.coverageAmount, "Claim exceeds coverage amount");

    policy.claimCount++; // Increment the claim count

    Claim memory newClaim = Claim({
        claimAmount: claimAmount,
        status: ClaimStatus.Pending,
        reason: reason
    });

    userClaims[msg.sender][policy.policyId].push(newClaim);
    emit ClaimSubmitted(msg.sender, policy.policyId, claimAmount);
}


    // Approve a claim (only authorized approvers)
    function approveClaim(address policyHolder, uint256 policyId, uint256 claimIndex) public onlyAuthorizedApprovers {
        Claim storage claim = userClaims[policyHolder][policyId][claimIndex];
        require(claim.status == ClaimStatus.Pending, "Claim already processed");

        Policy storage policy = userPolicies[policyHolder][policyId];
        require(policy.coverageAmount >= claim.claimAmount, "Insufficient coverage");

        claim.status = ClaimStatus.Approved;
        policy.coverageAmount -= claim.claimAmount; // Deduct the claim amount from coverage

        // Ensure contract has sufficient balance
        require(address(this).balance >= claim.claimAmount, "Contract has insufficient funds");

        // Payout to policyholder
        payable(policyHolder).transfer(claim.claimAmount);

        emit ClaimApproved(msg.sender, policyHolder, policyId, claim.claimAmount);
    }

    // Reject a claim (only authorized approvers)
    function rejectClaim(address policyHolder, uint256 policyId, uint256 claimIndex) public onlyAuthorizedApprovers {
        Claim storage claim = userClaims[policyHolder][policyId][claimIndex];
        require(claim.status == ClaimStatus.Pending, "Claim already processed");

        claim.status = ClaimStatus.Rejected;

        emit ClaimRejected(msg.sender, policyHolder, policyId, claim.claimAmount);
    }

    // Get the number of policies for a user
    function getUserPoliciesLength(address user) public view returns (uint256) {
        return userPolicies[user].length;
    }

    // Get the number of claims for a user's policy
    function getUserClaimsLength(address user, uint256 policyId) public view returns (uint256) {
        return userClaims[user][policyId].length;
    }

    // Get a specific claim for a user's policy
    function getUserClaim(address user, uint256 policyId, uint256 claimIndex)
        public
        view
        returns (uint256 claimAmount, uint8 status, string memory reason)
    {
        Claim storage claim = userClaims[user][policyId][claimIndex];
        return (claim.claimAmount, uint8(claim.status), claim.reason);
    }

    // Accept Ether deposits
    receive() external payable {}
}
