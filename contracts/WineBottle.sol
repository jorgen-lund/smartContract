// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WineBottle {
    address payable owner;

    enum Statuses { available, empty }
    Statuses public statuses;

    uint public wineLeft;

    event buyGlass(uint _value, address _renter);

    constructor() {
        owner = payable(msg.sender);
        statuses = Statuses.available;
        wineLeft = 75;
    }

    modifier costs(uint _amount) {
        require(msg.value >= _amount, "Not enough eth provided");
        _;
    }

    modifier isWineLeft {
        require(statuses == Statuses.available, "Bottle is empty");
        _;
    }

    function pourGlass() isWineLeft costs(1 ether) payable public {
        wineLeft -= 15;
        owner.transfer(msg.value);
        emit buyGlass(msg.value, msg.sender);
        if (wineLeft == 0) {
            statuses = Statuses.empty;
        }
    }
}