// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Lottery{
    address public president;
    address public president2;
    address public Car;
    address public Phone;
    address public Computer;
    uint public total_tickets;

    uint256 public carPoolLenght;
    uint256 public phonePoolLenght;
    uint256 public computerPoolLenght;

    uint public ticketPrice = 0.1 ether;

    struct Ticket{
        address buyer;
        bool isUsed;
    }

    struct LotteryPool{
        Ticket[] tickets;
    }

    mapping(address => LotteryPool) carPool;
    mapping(address => LotteryPool) phonePool;
    mapping(address => LotteryPool) computerPool;

    modifier onlyPresident(){
        require(msg.sender == president || msg.sender == president2, "Only the president can call this function");
        _;
    }

    modifier poolNotEmpty(LotteryPool storage pool){
        require(pool.tickets.length > 0, "Lottery Pool Is Empty");
        _;
    }

    constructor(){
        total_tickets = 0;
        president = msg.sender;
        president2 = address(0x153dfef4355E823dCB0FCc76Efe942BefCa86477);
        carPoolLenght = 0;
        phonePoolLenght = 0;
        computerPoolLenght = 0;
        Car = address(0);
        Phone = address(0);
        Computer = address(0);
    }

    function reset() public onlyPresident{
        Car = address(0);
        Phone = address(0);
        Computer = address(0);
        total_tickets = 0;
        carPoolLenght = 0;
        phonePoolLenght = 0;
        computerPoolLenght = 0;
    }

    function buyTicket(string memory _itemName) external payable {
        require(msg.value == ticketPrice, "Incorrect Ticket Price");
        require(msg.sender != president || msg.sender != president2, "Only users can buy Tickets");

        if(keccak256(abi.encodePacked(_itemName)) ==  keccak256(abi.encodePacked("car"))){
            carPool[Car].tickets.push(Ticket({buyer: msg.sender, isUsed: false}));
            carPoolLenght++;
        }
        if(keccak256(abi.encodePacked(_itemName)) ==  keccak256(abi.encodePacked("phone"))){
            carPool[Phone].tickets.push(Ticket({buyer: msg.sender, isUsed: false}));
            phonePoolLenght++;
        }
        if(keccak256(abi.encodePacked(_itemName)) ==  keccak256(abi.encodePacked("computer"))){
            carPool[Computer].tickets.push(Ticket({buyer: msg.sender, isUsed: false}));
            computerPoolLenght++;
        }
        if((keccak256(abi.encodePacked(_itemName)) ==  keccak256(abi.encodePacked("car"))) &&
        (keccak256(abi.encodePacked(_itemName)) ==  keccak256(abi.encodePacked("phone"))) && 
        (keccak256(abi.encodePacked(_itemName)) ==  keccak256(abi.encodePacked("computer")))){
            revert("Invalid Item");
        }
        total_tickets++;
    }

    function drawWinners() external onlyPresident{
        address carWinner = drawWinnersFromPool(carPool[Car]);
        address phoneWinner = drawWinnersFromPool(phonePool[Phone]);
        address computerWinner = drawWinnersFromPool(computerPool[Computer]);

        if(carWinner != address(0)){
            emit WinnerAnnounced("Car", carWinner);
            Car = carWinner;
        }
        if(phoneWinner != address(0)){
            emit WinnerAnnounced("Phone", phoneWinner);
            Phone = phoneWinner;
        }
        if(computerWinner != address(0)){
            emit WinnerAnnounced("Computer", computerWinner);
            Computer = computerWinner;
        }
    }

    function random(uint max) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(blockhash(block.number-1), block.timestamp, president))) % max;
    }

    function drawWinnersFromPool(LotteryPool storage pool) internal poolNotEmpty(pool) returns (address) {
        uint randIndex = random(pool.tickets.length);
        address winner = pool.tickets[randIndex].buyer;
        pool.tickets[randIndex].isUsed = true;
        return winner;
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() public onlyPresident {
        address payable ownerPayable = payable (president);
        ownerPayable.transfer(address(this).balance);
    }

    function destroyContract() external onlyPresident {
        selfdestruct(payable(president));
    }
    
    function transferOwnership(address newOwner) external onlyPresident {
        require(newOwner != address(0), "Invalid Owners Address");
        president = newOwner;
    }

    event WinnerAnnounced(string _itemName, address winner);
}