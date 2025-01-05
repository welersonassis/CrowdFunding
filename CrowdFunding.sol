// SPDX-license-Identifier: MIT
pragma solidity ^0.8.24;

contract CrowdFunding {
    error CrowdFunding__AmountMustBeGreaterThanZero();
    error CrowdFunding__CampaingHasEnded();
    error CrowdFunding__OnlyOwnerCanWithdraw();
    error CrowdFunding__GoalHasNotBeenReached();
    error CrowdFunding__NoBalanceToWithdrawn();
    error CrowdFunding__TierDoesNotExist();
    error CrowdFunding__IncorrectAmount();
    error CrowdFunding__CampaingIsNotActive();
    error CrowdFunding__CampaingIsNotSuccessful();
    error CrowdFunding__RefundsNotAvaiable();
    error CrowdFunding__NoContributionsToRefund();

    string public name;
    string public description;
    uint256 public goal;
    uint256 public deadline;
    address public owner;

    enum campaignState {
        Active,
        Failed,
        Succeeded
    }
    campaignState public state;

    struct Tier {
        string name;
        uint256 amount;
        uint256 backers;
    }

    struct Backer {
        uint256 totalContribution;
        mapping(uint256 => bool) fundedTiers;
    }

    Tier[] public tiers;
    mapping(address => Backer) public backers;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert CrowdFunding__OnlyOwnerCanWithdraw();
        }
        _;
    }

    modifier campaignOpen() {
        if (state != campaignState.Active) {
            revert CrowdFunding__CampaingIsNotActive();
        }
        _;
    }

    constructor(
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) {
        name = _name;
        description = _description;
        goal = _goal;
        deadline = block.timestamp + (_durationInDays * 1 days);
        owner = msg.sender;
        state = campaignState.Active;
    }

    function checkAndUpdateCampaignState() internal {
        if (state == campaignState.Active) {
            if (block.timestamp >= deadline) {
                state = address(this).balance >= goal
                    ? campaignState.Succeeded
                    : campaignState.Failed;
            } else {
                state = address(this).balance >= goal
                    ? campaignState.Succeeded
                    : campaignState.Active;
            }
        }
    }

    function fund(uint256 _tierIndex) public payable campaignOpen {
        if (_tierIndex >= tiers.length) {
            revert CrowdFunding__TierDoesNotExist();
        }

        if (msg.value != tiers[_tierIndex].amount) {
            revert CrowdFunding__IncorrectAmount();
        }

        tiers[_tierIndex].backers++;
        backers[msg.sender].totalContribution += msg.value;
        backers[msg.sender].fundedTiers[_tierIndex] = true;

        checkAndUpdateCampaignState();
    }

    function refund() public {
        checkAndUpdateCampaignState();
        if (state != campaignState.Failed) {
            revert CrowdFunding__RefundsNotAvaiable();
        }

        uint256 amount = backers[msg.sender].totalContribution;

        if (amount <= 0) {
            revert CrowdFunding__NoContributionsToRefund();
        }

        backers[msg.sender].totalContribution = 0;
        payable(msg.sender).transfer(amount);
    }

    function hasFundedTier(
        address _backer,
        uint256 _tierIndex
    ) public view returns (bool) {
        return backers[_backer].fundedTiers[_tierIndex];
    }

    function addTier(string memory _name, uint256 _amount) public onlyOwner {
        if (_amount <= 0) {
            revert CrowdFunding__AmountMustBeGreaterThanZero();
        }

        tiers.push(Tier({name: _name, amount: _amount, backers: 0}));
    }

    function removeTier(uint256 _index) public onlyOwner {
        if (_index >= tiers.length) {
            revert CrowdFunding__TierDoesNotExist();
        }

        tiers[_index] = tiers[tiers.length - 1];

        tiers.pop();
    }

    function withdraw() public onlyOwner {
        checkAndUpdateCampaignState();
        if (state != campaignState.Succeeded) {
            revert CrowdFunding__CampaingIsNotSuccessful();
        }
        if (address(this).balance < goal) {
            revert CrowdFunding__GoalHasNotBeenReached();
        }

        uint256 balance = address(this).balance;

        if (balance <= 0) {
            revert CrowdFunding__NoBalanceToWithdrawn();
        }

        payable(owner).transfer(balance);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
