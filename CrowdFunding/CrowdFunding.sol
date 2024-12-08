// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {

    address public owner;
    uint public campaignFee = 0.02 ether;
    mapping(uint => Campaign) public campaigns;
    mapping(address => bool) public bannedEntrepreneurs;
    mapping(address => mapping(uint => uint)) public backerInvestments;
    uint public nextCampaignId;
    uint public totalFeesCollected;

    struct Campaign {
        uint campaignId;
        address entrepreneur;
        string title;
        uint pledgeCost;
        uint pledgesNeeded;
        uint pledgesCount;
        bool fulfilled;
        bool cancelled;
        address[] backers;
        uint totalFunds;
    }

    event CampaignCreated(uint campaignId, address entrepreneur, string title);
    event PledgeMade(uint campaignId, address backer, uint amount);
    event CampaignCancelled(uint campaignId);
    event CampaignCompleted(uint campaignId, uint totalFunds);
    event FundsWithdrawn(address owner, uint amount);
    event EntrepreneurBanned(address entrepreneur);
    event OwnershipTransferred(address newOwner);
    event ContractDestroyed();

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier notBanned() {
        require(!bannedEntrepreneurs[msg.sender], "Entrepreneur is banned");
        _;
    }

    modifier onlyEntrepreneur(uint campaignId) {
        require(msg.sender == campaigns[campaignId].entrepreneur, "Not authorized");
        _;
    }

    modifier notCancelled(uint campaignId) {
        require(!campaigns[campaignId].cancelled, "Campaign is cancelled");
        _;
    }

    modifier campaignActive(uint campaignId) {
        require(campaigns[campaignId].pledgesCount < campaigns[campaignId].pledgesNeeded, "Campaign is full");
        require(!campaigns[campaignId].fulfilled, "Campaign is already fulfilled");
        _;
    }

    modifier campaignNotFulfilled(uint campaignId) {
        require(!campaigns[campaignId].fulfilled, "Campaign already fulfilled");
        _;
    }

    modifier campaignNotCancelled(uint campaignId) {
        require(!campaigns[campaignId].cancelled, "Campaign is cancelled");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createCampaign(string memory title, uint pledgesNeeded) public payable notBanned {
        require(msg.value == campaignFee, "Incorrect campaign fee");

        uint pledgeCost = 0.02 ether;
        uint campaignId = nextCampaignId++;
        Campaign storage newCampaign = campaigns[campaignId];
        newCampaign.campaignId = campaignId;
        newCampaign.entrepreneur = msg.sender;
        newCampaign.title = title;
        newCampaign.pledgeCost = pledgeCost;
        newCampaign.pledgesNeeded = pledgesNeeded;
        newCampaign.pledgesCount = 0;
        newCampaign.fulfilled = false;
        newCampaign.cancelled = false;

        totalFeesCollected += msg.value;

        emit CampaignCreated(campaignId, msg.sender, title);
    }

    function pledge(uint campaignId, uint amount) public payable campaignActive(campaignId) {
        require(msg.value == amount * campaigns[campaignId].pledgeCost, "Incorrect pledge amount");

        Campaign storage campaign = campaigns[campaignId];
        campaign.pledgesCount += amount;
        campaign.totalFunds += msg.value;

        // Ενημέρωση για τον επενδυτή
        backerInvestments[msg.sender][campaignId] += amount;
        campaign.backers.push(msg.sender);

        emit PledgeMade(campaignId, msg.sender, msg.value);
    }

    function cancelCampaign(uint campaignId) public onlyEntrepreneur(campaignId) campaignNotFulfilled(campaignId) {
        Campaign storage campaign = campaigns[campaignId];
        campaign.cancelled = true;

        for (uint i = 0; i < campaign.backers.length; i++) {
            address backer = campaign.backers[i];
            uint investment = backerInvestments[backer][campaignId];
            if (investment > 0) {
                payable(backer).transfer(investment);
                backerInvestments[backer][campaignId] = 0;
            }
        }

        emit CampaignCancelled(campaignId);
    }

    function completeCampaign(uint campaignId) public onlyEntrepreneur(campaignId) campaignNotCancelled(campaignId) {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.pledgesCount >= campaign.pledgesNeeded, "Not enough pledges");

        uint amountToTransfer = (campaign.totalFunds * 80) / 100;
        payable(campaign.entrepreneur).transfer(amountToTransfer);

        campaign.fulfilled = true;

        emit CampaignCompleted(campaignId, campaign.totalFunds);
    }

    function refundInvestor(uint campaignId) public {
        Campaign storage campaign = campaigns[campaignId];
        require(campaign.cancelled, "Campaign not cancelled");

        uint investment = backerInvestments[msg.sender][campaignId];
        require(investment > 0, "No investment found");

        payable(msg.sender).transfer(investment);
        backerInvestments[msg.sender][campaignId] = 0;
    }

    function getActiveCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory activeCampaigns = new Campaign[](nextCampaignId);
        uint counter = 0;
        for (uint i = 0; i < nextCampaignId; i++) {
            if (!campaigns[i].fulfilled && !campaigns[i].cancelled) {
                activeCampaigns[counter] = campaigns[i];
                counter++;
            }
        }
        return activeCampaigns;
    }

    function getCancelledCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory cancelledCampaigns = new Campaign[](nextCampaignId);
        uint counter = 0;
        for (uint i = 0; i < nextCampaignId; i++) {
            if (campaigns[i].cancelled) {
                cancelledCampaigns[counter] = campaigns[i];
                counter++;
            }
        }
        return cancelledCampaigns;
    }

    function getCompletedCampaigns() public view returns (Campaign[] memory) {
        Campaign[] memory completedCampaigns = new Campaign[](nextCampaignId);
        uint counter = 0;
        for (uint i = 0; i < nextCampaignId; i++) {
            if (campaigns[i].fulfilled) {
                completedCampaigns[counter] = campaigns[i];
                counter++;
            }
        }
        return completedCampaigns;
    }

    function withdrawFees() public onlyOwner {
        uint amount = totalFeesCollected;
        totalFeesCollected = 0;
        payable(owner).transfer(amount);

        emit FundsWithdrawn(owner, amount);
    }

    function banEntrepreneur(address entrepreneur) public onlyOwner {
        bannedEntrepreneurs[entrepreneur] = true;

        emit EntrepreneurBanned(entrepreneur);
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(newOwner);
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function destroyContract() public onlyOwner {
        emit ContractDestroyed();
        selfdestruct(payable(owner));
    }
}
