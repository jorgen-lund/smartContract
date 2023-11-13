// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CarSharing {
    address payable public owner;

    uint public seatsLeft;

    event bookSeat(uint _value, address _renter); 

    enum Statuses { seatsLeft, full }

    Statuses public currentStatus;

    constructor() {
    owner = payable(msg.sender);
    seatsLeft = 4;
    currentStatus = Statuses.seatsLeft;
    }

    modifier costs(uint _amount) {
        require(msg.value >= 1 ether, "Not enough ether provided");
        _;
    }

    modifier isSeatsLeft {
        require(currentStatus == Statuses.seatsLeft, "No seats are left to book");
        _;
    }

    function payForSeat() costs(1 ether) isSeatsLeft public payable {

        owner.transfer(msg.value);
        emit bookSeat(msg.value, msg.sender);
        seatsLeft -= 1;
        if (seatsLeft == 0) {
            currentStatus = Statuses.full;
        }
    }
}