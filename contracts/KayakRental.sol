// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KayakRental {

    enum Statuses { available, unavailable }

    event RentKayak(address _renter, uint _value);

    Statuses currentStatus;
    address payable public owner;

    constructor() {
        owner = payable(msg.sender);
        currentStatus = Statuses.available;
    }

    modifier isAvailable {
        require(currentStatus == Statuses.available, "Kayak already in use");
        _;
    }

    modifier costs(uint _amount) {
        require(msg.value >= _amount, "Not enough eth provided");
        _;
    }

    function bookKayak() payable isAvailable costs(1 ether) public {
        currentStatus = Statuses.unavailable;
        owner.transfer(msg.value);

        emit RentKayak(msg.sender, msg.value);
    }
}