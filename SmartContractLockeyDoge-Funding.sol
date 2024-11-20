// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LockyDogeFunding {
    
    // Enum for project state
    enum ProjectState { Created, OpenForFunding, FundingClosed, FundWithdrawn }
    
    // Struct for a project proposal
    struct Project {
        address payable owner;
        string description;
        uint fundingGoal;
        uint amountRaised;
        ProjectState state;
    }
    
    // State variables
    mapping(uint => Project) public projects;
    mapping(uint => mapping(address => uint)) public contributions;
    uint public projectCount;
    address public admin;
    
    // Events
    event ProjectCreated(uint projectId, address indexed owner, string description, uint fundingGoal);
    event FundingReceived(uint projectId, address indexed investor, uint amount);
    event ProjectApproved(uint projectId);
    event FundingClosed(uint projectId);
    event FundsWithdrawn(uint projectId, uint amount);
    event ProjectStarted(uint projectId);
    
    // Admin Only Modifier
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    // Owner Only Modifier
    modifier onlyOwner(uint projectId) {
        require(msg.sender == projects[projectId].owner, "Only the project owner can perform this action");
        _;
    }
    
    // Modifier to check project state
    modifier inState(uint projectId, ProjectState _state) {
        require(projects[projectId].state == _state, "Invalid project state for this action");
        _;
    }
    
    // Constructor to set the admin
    constructor() {
        admin = msg.sender;
    }
    
    // Public function to create a project proposal
    function createProject(string memory description, uint fundingGoal) public {
        projectCount++;
        projects[projectCount] = Project({
            owner: payable(msg.sender),
            description: description,
            fundingGoal: fundingGoal,
            amountRaised: 0,
            state: ProjectState.Created
        });
        emit ProjectCreated(projectCount, msg.sender, description, fundingGoal);
    }
    
    // Admin function to approve and open a project for funding
    function approveProject(uint projectId) public onlyAdmin inState(projectId, ProjectState.Created) {
        projects[projectId].state = ProjectState.OpenForFunding;
        emit ProjectApproved(projectId);
    }
    
    // Admin function to close the funding period
    function closeFundingPeriod(uint projectId) public onlyAdmin inState(projectId, ProjectState.OpenForFunding) {
        projects[projectId].state = ProjectState.FundingClosed;
        emit FundingClosed(projectId);
    }
    
    // Public payable function to fund a project
    function fundProject(uint projectId) public payable inState(projectId, ProjectState.OpenForFunding) {
        require(msg.value > 0, "Funding amount must be greater than zero");
        
        Project storage project = projects[projectId];
        project.amountRaised += msg.value;
        contributions[projectId][msg.sender] += msg.value;
        
        emit FundingReceived(projectId, msg.sender, msg.value);
    }
    
    // Function for project creator to withdraw funds if funding goal is met
    function withdrawFunds(uint projectId) public onlyOwner(projectId) inState(projectId, ProjectState.FundingClosed) {
        Project storage project = projects[projectId];
        require(project.amountRaised >= project.fundingGoal, "Funding goal not reached");
        
        uint amount = project.amountRaised;
        project.amountRaised = 0;
        project.state = ProjectState.FundWithdrawn;
        
        project.owner.transfer(amount);
        emit FundsWithdrawn(projectId, amount);
        emit ProjectStarted(projectId);
    }
    
    // View function to get project details
    function getProject(uint projectId) public view returns (address, string memory, uint, uint, ProjectState) {
        Project storage project = projects[projectId];
        return (project.owner, project.description, project.fundingGoal, project.amountRaised, project.state);
    }
}
