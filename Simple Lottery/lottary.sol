// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Lottery {
    struct Person {
        uint personId;
        address addr;
        uint remainingTokens;
    }

    struct Item {
        uint itemId;
        address winner;
        address[] itemTokens;
    }

    mapping(address => Person) public tokenDetails;
    mapping(address => Item) public itemDetails;
    Person[] public bidders; //Array of bidders
    Item[] public items; // Dynamic array for items
    address[] public winners; // Array of winners
    address public beneficiary; //contract owner
    uint public bidderCount = 0; //count bidders
    uint public reset_times = 0; //contract reset counter

    enum Stage {Init, Reg, Bid, Done}
    Stage public stage;


    //MODIFIERS
    //
    //
    //
    modifier onlyOwner() {
        require(msg.sender == beneficiary, "Only the owner can call this function");
        _;
    }

    modifier register_modifier(){
        uint256 requiredAmount = 0.005 ether;
        require(msg.sender.balance >= requiredAmount, "Insufficient balance");
        require(msg.sender != beneficiary, "Owner cant call this function");
        require(tokenDetails[msg.sender].addr != msg.sender, "User is already registered");
        _;
    }

    modifier bid_modifier() {
        require(tokenDetails[msg.sender].remainingTokens > 0, "Not enough tokens");
        _;
    }
    //
    //
    //

    constructor() payable {
        beneficiary = msg.sender;
        initializeItems();
    }

    function initializeItems() private {
        address[] memory emptyArray;
        address e;
        for(uint i=0; i<items.length; i++){
            items[i] = Item({itemId : i, winner: e, itemTokens : emptyArray});
        }
    }

    function reset() public onlyOwner{
        for(uint i=0; i<bidders.length; i++){
            bidders.pop();
        }
        for(uint j=0; j<items.length; j++){
            items.pop();
        }
        for(uint k=0; k<winners.length; k++){
            winners.pop();
        }
        stage = Stage.Init;
        bidderCount = 0;
        reset_times++;
    }

    function addBidder() private{
        bidders.push(Person({
            personId: bidderCount,
            addr: msg.sender,
            remainingTokens: 5
        }));
        tokenDetails[msg.sender] = bidders[bidderCount];
        bidderCount++;
    }

    function advanceState () public {
        if (stage == Stage.Init) {stage = Stage.Reg; return;}
        if (stage == Stage.Reg) {stage = Stage.Bid; return;}
        if (stage == Stage.Bid) {stage = Stage.Done; return;}
    }

    function withdraw() public onlyOwner{
        address payable ownerPayable = payable(beneficiary);
        ownerPayable.transfer(address(this).balance);
    }

    function addItem() public payable {
        uint itemId = items.length;
        address[] memory emptyArray;
        address e;
        items.push(Item({
            itemId: itemId,
            winner: e,
            itemTokens: emptyArray
        }));
    }

    function register() public payable register_modifier{
        require(stage == Stage.Reg, "Registration not allowed at this stage");
        addBidder(); // Call this function to register bidders

        uint256 transferAmount = 0.005 ether; // 0.005 ether fee
        require(address(this).balance >= transferAmount, "Insufficient contract balance");

        // Μεταφορά χρημάτων στον ιδιοκτήτη
        payable(msg.sender).transfer(transferAmount);
    }

    function bid(uint _itemId, uint _count) public bid_modifier { 
        require(stage == Stage.Bid, "Bidding not allowed at this stage");
        // Ποντάρει _count λαχεία στο αντικείμενο _itemId
        tokenDetails[msg.sender].remainingTokens -= _count;
            
        // Προσθήκη του _count στα itemTokens του συγκεκριμένου αντικειμένου
        for(uint i=0; i<_count; i++){
            items[_itemId].itemTokens.push(msg.sender);
        }
    }

    function remainingTokens() public view returns (uint) {
        return (tokenDetails[msg.sender].remainingTokens);
    }

    function revealWinners() public onlyOwner {
        address k;
        address winnerAddress;
        for(uint i=0; i<items.length; i++){
            if((items[i].winner == k) && (items[i].itemTokens.length > 0)){
                uint256 randomNumber = (uint256(keccak256(abi.encodePacked(block.timestamp)))) % items[i].itemTokens.length;
                //require(randomNumber < items[i].itemTokens.length, "Random number out of bounds");
                winnerAddress = items[i].itemTokens[randomNumber];
                
                winners.push(winnerAddress);
            }else{
                winners.push(address(0));
            }
        }
    }

    function revealWinnersAdresses() public view onlyOwner returns (address[] memory) {
        return winners;
    }
}