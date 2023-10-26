// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract HotelRoom {
    enum Statuses { Vacant, Occupied }
    Statuses public currentStatus;

    event Occupy(address _occupant, uint _value);

    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        currentStatus = Statuses.Vacant;
    }

    // A way to provide cleaner code with modifier.
    modifier onlyWhileVacant {
        require(currentStatus == Statuses.Vacant, "Currently occupied.");
        _;
    }

    modifier costs(uint _amount) {
        require(msg.value >= _amount, "Not enough Ether.");
        _;

    }
    // Pay owner, and book the room.
    function bookRoom() payable onlyWhileVacant costs(2 ether) public {
        currentStatus = Statuses.Occupied;

        //owner.transfer(msg.value);
        (bool sent, bytes memory data) = owner.call{value: msg.value}("");
        require(sent, "Failed to send data");
        // Call the event made at the top
        // An alert when someone books, and see log of all bookings.
        emit Occupy(msg.sender, msg.value);
    }
}