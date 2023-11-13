// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EngagementRegistry {
    struct Engagement {
        address spouse1;
        address spouse2;
        uint256 weddingDate;
        bool isEngaged;
        bool isRevoked;
    }

    mapping(address => Engagement) public engagements;

    event EngagementRegistered(address spouse1, address spouse2, uint256 weddingDate);
    event EngagementRevoked(address caller, uint256 revokedDate);

    modifier notEngaged(address _spouse1, address _spouse2) {
        require(
            engagements[_spouse1].isEngaged == false && engagements[_spouse2].isEngaged == false,
            "Oopsie, one of the parts are already engaged!"
        );
        _;
    }

    modifier onlyEngaged(address _spouse) {
        require(engagements[_spouse].isEngaged == true, "You are not engaged.");
        _;
    }

    modifier notRevoked(address _spouse) {
        require(engagements[_spouse].isRevoked == false, "The engagement is already revoked.");
        _;
    }

    modifier futureDate(uint _date) {
        require(_date > block.timestamp, "Date must be in the future");
        _;

    }

    function registerEngagement(address _spouse, uint256 _weddingDate) external notEngaged(msg.sender, _spouse) futureDate(_weddingDate){
        Engagement memory engagement = Engagement({
            spouse1: msg.sender,
            spouse2: _spouse,
            weddingDate: _weddingDate,
            isEngaged: true,
            isRevoked: false
        });

        engagements[msg.sender] = engagement;
        engagements[_spouse] = engagement;

        emit EngagementRegistered(msg.sender, _spouse, _weddingDate);
    }

    function revokeEngagement() external onlyEngaged(msg.sender) notRevoked(msg.sender) {
        Engagement storage engagement = engagements[msg.sender];

        require(block.timestamp < engagement.weddingDate, "Revoking the engagement must happen before the wedding date");

        delete engagements[engagement.spouse1];
        delete engagements[engagement.spouse2];

        emit EngagementRevoked(msg.sender, block.timestamp);
    }

    function getEngagementInfo(address _spouse) external view returns (address, address, uint256, bool, bool) {
        Engagement memory engagement = engagements[_spouse];
        return (engagement.spouse1, engagement.spouse2, engagement.weddingDate, engagement.isEngaged, engagement.isRevoked);
    }
}
