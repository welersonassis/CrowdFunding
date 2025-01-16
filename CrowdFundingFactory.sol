// SPDX-license-Identifier: MIT
pragma solidity ^0.8.24;

import {CrowdFunding} from "./CrowdFunding.sol";

contract CrowdFundingFactory {
    address public owner;
    bool public paused;

    struct Campaign {
        address addr;
        address owner;
        string name;
        uint256 createdAt;
    }

    Campaign[] public campaigns;
    mapping(address => Campaign[]) public userCampaign;

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert("CrowdFundingFactory__OnlyOwnerCanCreateCampaign");
        }
        _;
    }

    modifier notPaused() {
        if (paused) {
            revert("CrowdFundingFactory__ContractIsPaused");
        }
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createCampaign(
        string memory _name,
        string memory _description,
        uint256 _goal,
        uint256 _durationInDays
    ) external notPaused returns (address) {
        CrowdFunding newCampaign = new CrowdFunding(
            msg.sender,
            _name,
            _description,
            _goal,
            _durationInDays
        );

        Campaign memory campaign = Campaign({
            addr: address(newCampaign),
            owner: msg.sender,
            name: _name,
            createdAt: block.timestamp
        });

        campaigns.push(campaign);
        userCampaign[msg.sender].push(campaign);

        return address(newCampaign);
    }

    function getUserCampaigns(
        address _user
    ) external view returns (Campaign[] memory) {
        return userCampaign[_user];
    }

    function getAllCampaigns() external view returns (Campaign[] memory) {
        return campaigns;
    }

    function togglePause() external onlyOwner {
        paused = !paused;
    }
}
