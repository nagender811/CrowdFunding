// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract CrowdFunding {
    error InvalidGaol();
    error InvalidDuration();
    error CampaignNotActive();
    error CampaignEnded();
    error InvalidContribution();
    error NotCreator();
    error CampaignNotEnded();
    error AlreadyWithdrawn();
    error GoalNotReached();
    error TransferFailed();
    error GoalReached();
    error NoContribution();

    event CampaignCreated(
        uint256 indexed campaignId,
        address indexed creater,
        uint256 goal,
        uint256 deadline
    );

    event CampaignFunded(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
    );

    event FundsWithdrawn(
        uint256 indexed campaignId,
        address indexed creator,
        uint256 amount
    );

    event RefundClaimed(
        uint256 indexed campaignId,
        address indexed contributor,
        uint256 amount
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

    function fundCampaign(uint256 campaignId) external payable {
        Campaign storage campaign = campaigns[campaignId];

        if (campaign.status != CampaignStatus.ACTIVE)
            revert CampaignNotActive();

        if (block.timestamp > campaign.deadline) revert CampaignEnded();

        if (msg.value == 0) revert InvalidContribution();

        campaign.amountRaised += msg.value;
        contributions[campaignId][msg.sender] += msg.value;

        emit CampaignFunded(campaignId, msg.sender, msg.value);
    }

    function withdrawFunds(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];

        if (msg.sender == campaign.creator) revert NotCreator();

        if (block.timestamp < campaign.deadline) revert CampaignNotEnded();

        if (campaign.withdrawn) revert AlreadyWithdrawn();

        if (campaign.goal > campaign.amountRaised) revert GoalNotReached();

        campaign.withdrawn = true;
        campaign.status = CampaignStatus.SUCCESSFUL;

        uint256 amount = campaign.amountRaised;

        (bool success, ) = payable(campaign.creator).call{value: amount}("");

        if (!success) revert TransferFailed();

        emit FundsWithdrawn(campaignId, campaign.creator, amount);
    }

    function claimRefund(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];

        if (block.timestamp < campaign.deadline) revert CampaignNotEnded();

        if (campaign.amountRaised >= campaign.goal) revert GoalReached();

        campaign.status = CampaignStatus.FAILED;

        uint256 amount = contributions[campaignId][msg.sender];

        if (amount == 0) revert NoContribution();

        contributions[campaignId][msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) revert TransferFailed();

        emit RefundClaimed(campaignId, msg.sender, amount);
    }
}
