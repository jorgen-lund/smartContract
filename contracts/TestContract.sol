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

contract SecretVault {
    string secret;

    constructor(string memory _secret) {
        secret = _secret;
    }

    function getSecret() public view returns(string memory) {
        return secret;
    }
}

// This is a "Factory, a smartContract that creates other smartContracts.
contract TestContract is Ownable {
    address secretVaultAddr;

    constructor(string memory _secret) {
        // This is how one creates a new smartContract within a smartContract.
        SecretVault _secretVault = new SecretVault(_secret);
        secretVaultAddr = address(_secretVault);
        super;
    }

    function getSecret() public view onlyOwner returns(string memory) {
        return SecretVault(secretVaultAddr).getSecret();
    }
}