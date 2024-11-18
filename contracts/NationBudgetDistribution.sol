// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract NationBudgetDistribution {

    // Structure to represent a sector
    struct Sector {
        uint id;
        string name;
        uint voteCount;
    }

    // Structure to represent a candidate's proposal
    struct Proposal {
        address candidate;
        uint[] allocations;
        uint totalAllocation;
    }

    // Owner of the contract (Government)
    address public owner;

    // Total budget to be distributed
    uint public totalBudget;

    Sector[] public sectors;

    Proposal[] public proposals;

    mapping(address => bool) public hasVoted;

    mapping(address => bool) public hasSubmittedProposal;

    event VoteCast(address voter, uint proposalId);

    event ProposalSubmitted(address candidate, uint proposalId);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier budgetSet() {
        require(totalBudget > 0, "Total budget must be set first");
        _;
    }

    constructor() {
        owner = msg.sender;
        totalBudget = 50000000; // Set the initial budget to 50,000,000
        addSector("Education");
        addSector("Healthcare");
        addSector("Infrastructure");
        addSector("Defense");
        addSector("Technology");
    }


    // Function to set the total budget accessible by only the admin
    function setTotalBudget(uint _totalBudget) public onlyOwner {
        totalBudget = _totalBudget;
    }

    // Function to add a new sector apart from pre-set sectors
    function addSector(string memory _name) public onlyOwner {
        uint sectorId = sectors.length;
        sectors.push(Sector(sectorId, _name, 0));
    }

    // Function to submit a proposal in the form of an integer array
    function submitProposal(uint[] memory _allocations) public budgetSet {
        require(_allocations.length == sectors.length, "Proposal must allocate budget for all sectors.");
        require(!hasSubmittedProposal[msg.sender], "You have already submitted a proposal.");

        uint totalAllocated = 0;
        uint proposalId = proposals.length;

        proposals.push();
        Proposal storage newProposal = proposals[proposalId];
        newProposal.candidate = msg.sender;
        newProposal.allocations = _allocations;

        for (uint i = 0; i < _allocations.length; i++) {
            totalAllocated += _allocations[i];
        }

        // Requirement for the total allocation to be equal to the budget
        require(totalAllocated == totalBudget, "The total allocation must match the total budget.");
        newProposal.totalAllocation = totalAllocated;

        hasSubmittedProposal[msg.sender] = true;

        emit ProposalSubmitted(msg.sender, proposalId);
    }

    // Function for citizen voting
    function vote(uint _proposalId) public {
        require(!hasVoted[msg.sender], "You have already voted.");
        require(_proposalId >= 0 && _proposalId < proposals.length, "Invalid proposal ID.");

        hasVoted[msg.sender] = true;

        for (uint i = 0; i < sectors.length; i++) {
            sectors[i].voteCount += proposals[_proposalId].allocations[i];
        }

        emit VoteCast(msg.sender, _proposalId);
    }

    // Function to obtain the winning proposal
    function getWinningProposal() public view returns (uint winningProposalId, uint winningVoteCount) {
        uint maxVoteCount = 0;

        for (uint i = 0; i < proposals.length; i++) {
            uint proposalVoteCount = 0;
            for (uint j = 0; j < sectors.length; j++) {
                proposalVoteCount += proposals[i].allocations[j];
            }
            if (proposalVoteCount > maxVoteCount) {
                maxVoteCount = proposalVoteCount;
                winningProposalId = i;
            }
        }

        winningVoteCount = maxVoteCount;
    }

    // Function to obtain the allocations in a proposal by entering the proposal id
    function getProposalAllocations(uint _proposalId) public view returns (uint[] memory) {
        require(_proposalId >= 0 && _proposalId < proposals.length, "Invalid proposal ID.");
        return proposals[_proposalId].allocations;
    }

    // Function to view all the available sectors
    function getSectors() public view returns (Sector[] memory) {
        return sectors;
    }

    // Function to view the details of a proposal
    function viewProposal(uint _proposalId) public view returns (address candidate, uint[] memory allocations, uint totalAllocation) {
        require(_proposalId >= 0 && _proposalId < proposals.length, "Invalid proposal ID.");

        Proposal storage proposal = proposals[_proposalId];
        return (proposal.candidate, proposal.allocations, proposal.totalAllocation);
    }

    // New function to view all submitted proposals
    function getAllProposals() public view returns (Proposal[] memory) {
        return proposals;
    }
}