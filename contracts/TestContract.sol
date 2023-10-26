// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() {
        owner = msg.sender;
    }
}

contract TestContract is Ownable {
    string secret;

    constructor(string memory _secret) {
        secret = _secret;
        super;
    }

    function getSecret() public view onlyOwner returns(string memory) {
        return secret;
    }
}