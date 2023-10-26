// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CondAndLoops {
    
    address public owner;
    uint[] public numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

    constructor() {
        //Ownable contract, gets special priviliges for example.
        owner = msg.sender;
    }

    function isEvenNumber(uint _number) public pure returns(bool) {
        return (_number % 2 == 0 ? true : false);
    }

    function countEvenNumbers() public view returns(uint) {
        uint count = 0;
        
        for(uint i = 0; i < numbers.length; i++) {
            if (isEvenNumber(numbers[i])) {
                count++;
            }
        }
        return count;
    }

    function isOwner() public view returns(bool) {
        // Checks if caller of this function is the owner of the smart contract
        return(msg.sender == owner);
    }

}