// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CrowdFunding {
    error InvalidGaol();
    error InvalidDuration();

    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creater,
        uint256 goal,
        uint256 deadline
    );

    enum CampaignStatus {
        ACTIVE,
        SUCCESSFUL,
        FAILED
    }

    struct Campaign {
        address creator;
        uint256 goal;
        uint256 deadline;
        uint256 amountRaised;
        CampaignStatus status;
        bool withdrawn;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;

    mapping(uint256 => mapping(address => uint256)) public contributions;

    function createCampaign(
        uint256 goal,
        uint256 duration
    ) external returns (uint256) {
        if (goal == 0) revert InvalidGaol();
        if (duration == 0) revert InvalidDuration();

        uint256 campaignId = campaignCount++;

        campaigns[campaignId] = Campaign({
            creator: msg.sender,
            goal: goal,
            deadline: block.timestamp + duration,
            amountRaised: 0,
            status: CampaignStatus.ACTIVE,
            withdrawn: false
        });

        emit CampaignCreated(
            campaignId,
            msg.sender,
            goal,
            block.timestamp + duration
        );
        return campaignId;
    }
}
