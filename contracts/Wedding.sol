// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EngagementRegistry {
    struct Engagement {
        address spouse1;
        address spouse2;
        uint256 weddingDate;
        bool isEngaged;
        bool isRevoked;
        bool isMarried;
        bool spouse1ConfirmedMarriage;
        bool spouse2ConfirmedMarriage;
    }

    struct GuestList {
        address[] proposedGuests;
        bool spouse1Confirmed;
        bool spouse2Confirmed;
        mapping(address => bool) hasVotedAgainst;
        uint256 votesAgainst;
    }

    mapping(address => Engagement) public engagements;
    mapping(address => GuestList) public guestLists;

    // EVENTS
    event EngagementRegistered(address spouse1, address spouse2, uint256 weddingDate);
    event EngagementRevoked(address caller, uint256 revokedDate);
    event GuestListProposed(address spouse, address[] guests);
    event GuestListConfirmed(address spouse);
    event MarriageConfirmed(address spouse1, address spouse2);
    event GuestVotedAgainst(address guest, address spouse);
    event WeddingInvalidated(address spouse);

    // MODIFIERS
    modifier notEngaged(address _spouse1, address _spouse2) {
        require(
            engagements[_spouse1].isEngaged == false && engagements[_spouse2].isEngaged == false,
            "One or both of the spouses are already engaged. "
        );
        _;
    }

    modifier isEngaged(address _spouse) {
        require(engagements[_spouse].isEngaged == true, "Address not engaged.");
        _;
    }

    modifier isEngagedParty(address _spouse) {
        Engagement memory engagement = engagements[_spouse];
        require(
            msg.sender == engagement.spouse1 || msg.sender == engagement.spouse2,
            "Caller must be one of the engaged parties"
        );
        _;
    }

    modifier notSameAddress(address _spouse) {
        require(msg.sender != _spouse, "Cannot engage to oneself");
        _;
    }
    
    modifier isNotRevoked(address _spouse) {
        require(engagements[_spouse].isRevoked == false, "The engagement is already revoked.");
        _;
    }

    modifier isNotMarried(address _spouse) {
        require(!engagements[_spouse].isMarried, "Already married");
        _;
    }


    modifier isConfirmedGuest(address _spouse) {
        require(isGuestConfirmed(_spouse, msg.sender), "Not a confirmed guest");
        _;
    }

    // TODO: Modifiers for date, musst be fixed as solidity is weird.
    modifier hasNotVoted(address _spouse) {
        require(!guestLists[_spouse].hasVotedAgainst[msg.sender], "Already voted");
        _;
    }

    modifier futureDate(uint _date) {
        require(_date > block.timestamp, "Date must be in the future");
        _;
    }

    modifier isBeforeWeddingDate(address _spouse) {
        Engagement memory engagement = engagements[_spouse];
        require(block.timestamp < engagement.weddingDate - 1 days, "The wedding date is already here");
        _;
    }

    modifier isVotingPeriod(address _spouse) {
        Engagement memory engagement = engagements[_spouse];
        require(block.timestamp >= engagement.weddingDate - 1 days, "Voting not yet open");
        require(block.timestamp < engagement.weddingDate, "Voting closed");
        _;
    }

    modifier weddingDateHasArrived(address _spouse) {
        require(block.timestamp >= engagements[_spouse].weddingDate, "Wedding date not yet arrived");
        _;
    }

    modifier weddingDateHasNotPassed(address _spouse) {
        require(block.timestamp < engagements[_spouse].weddingDate + 1 days, "Wedding date passed");
        _;
    }


// FUNCTIONS

    //ENGAGEMENT (TASK 1)
    function registerEngagement(address _spouse, uint256 _weddingDate) external
        notEngaged(msg.sender, _spouse)
        notSameAddress(_spouse)
    {
        Engagement memory engagement = Engagement({
            spouse1: msg.sender,
            spouse2: _spouse,
            weddingDate: _weddingDate,
            isEngaged: true,
            isRevoked: false,
            isMarried: false,
            spouse1ConfirmedMarriage: false,
            spouse2ConfirmedMarriage: false
        });

        engagements[msg.sender] = engagement;
        engagements[_spouse] = engagement;

        emit EngagementRegistered(msg.sender, _spouse, _weddingDate);
    }

    // PARTICIPATION (TASK 2)
    function proposeGuestList(address[] calldata _guests) external isEngaged(msg.sender) isEngagedParty(msg.sender) {
        Engagement storage engagement = engagements[msg.sender];

        // Reset confirmations for spouse 1
        guestLists[engagement.spouse1].proposedGuests = _guests;
        guestLists[engagement.spouse1].spouse1Confirmed = false;
        guestLists[engagement.spouse1].spouse2Confirmed = false;
        // Reset confirmations for spouse 2
        guestLists[engagement.spouse2].proposedGuests = _guests;
        guestLists[engagement.spouse2].spouse1Confirmed = false;
        guestLists[engagement.spouse2].spouse2Confirmed = false;

        emit GuestListProposed(msg.sender, _guests);
    }

    function confirmGuestList() external isEngaged(msg.sender) isEngagedParty(msg.sender) {
        Engagement storage engagement = engagements[msg.sender];

        // Confirm the guest list for both spouses
        if (msg.sender == engagement.spouse1) {
            guestLists[engagement.spouse1].spouse1Confirmed = true;
            guestLists[engagement.spouse2].spouse1Confirmed = true;
        } else {
            guestLists[engagement.spouse1].spouse2Confirmed = true;
            guestLists[engagement.spouse2].spouse2Confirmed = true;
        }

        // Emit event if both spouses have confirmed the guest list
        if (guestLists[engagement.spouse1].spouse1Confirmed && guestLists[engagement.spouse1].spouse2Confirmed) {
            emit GuestListConfirmed(engagement.spouse1);
        }
    }

    function isGuestConfirmed(address _spouse, address _guest) public view returns (bool) {
        GuestList storage guestList = guestLists[_spouse];

        if (guestList.spouse1Confirmed && guestList.spouse2Confirmed) {
            for (uint i = 0; i < guestLists[_spouse].proposedGuests.length; i++) {
                if (guestLists[_spouse].proposedGuests[i] == _guest) {
                    return true;
                }
            }
        }
        return false;
    }

    // REVOKE ENGAGEMENT (PART 3)
    function revokeEngagement() external isEngaged(msg.sender) isNotRevoked(msg.sender) {
        Engagement storage engagement = engagements[msg.sender];

        delete engagements[engagement.spouse1];
        delete engagements[engagement.spouse2];

        emit EngagementRevoked(msg.sender, block.timestamp);
    }

    // MARRY (PART 4)
    function marry() external 
        isEngaged(msg.sender) 
        isNotRevoked(msg.sender)
        isNotMarried(msg.sender)
    {
        Engagement storage engagement = engagements[msg.sender];

        // Confirm marriage for both spouses
        if (msg.sender == engagement.spouse1) {
            engagement.spouse1ConfirmedMarriage = true;
            engagements[engagement.spouse2].spouse1ConfirmedMarriage = true;
        } else if (msg.sender == engagement.spouse2) {
            engagement.spouse2ConfirmedMarriage = true;
            engagements[engagement.spouse1].spouse2ConfirmedMarriage = true;
        }

        // Check if both have confirmed, then emit
        if (engagement.spouse1ConfirmedMarriage && engagement.spouse2ConfirmedMarriage) {
            engagements[engagement.spouse1].isMarried = true; 
            engagements[engagement.spouse2].isMarried = true; 
            emit MarriageConfirmed(engagement.spouse1, engagement.spouse2);
        }
    }

    // VOTING (PART 5)
    function voteAgainstWedding(address _spouse) external 
        isEngaged(_spouse) 
        isNotRevoked(_spouse)
       
        isNotMarried(_spouse)
        isConfirmedGuest(_spouse)
        hasNotVoted(_spouse)
    {
        GuestList storage guestList = guestLists[_spouse];

        guestList.hasVotedAgainst[msg.sender] = true;
        guestList.votesAgainst++;
        emit GuestVotedAgainst(msg.sender, _spouse);

        _checkAndInvalidateWedding(_spouse);
    }

        // Internal helper function
    function _checkAndInvalidateWedding(address _spouse) internal 
        isEngaged(_spouse)
        isNotMarried(_spouse)
    {
        GuestList storage guestList = guestLists[_spouse];
        Engagement storage engagement = engagements[_spouse];

        uint256 confirmedGuestCount = guestList.proposedGuests.length;
        uint256 requiredVotesToInvalidate = (confirmedGuestCount + 1) / 2;

        if (guestList.votesAgainst >= requiredVotesToInvalidate) {
            engagements[engagement.spouse1].isRevoked = true;
            engagements[engagement.spouse2].isRevoked = true;

            emit WeddingInvalidated(engagement.spouse1);
            emit WeddingInvalidated(engagement.spouse2);
        }
    }

    // GETTERS FOR DEBUG
    function getGuestList(address _spouse) external view returns (address[] memory) {
        return guestLists[_spouse].proposedGuests;
    }

    function getEngagementInfo(address _spouse) external view returns (address, address, uint256, bool, bool) {
        Engagement memory engagement = engagements[_spouse];
        return (engagement.spouse1, engagement.spouse2, engagement.weddingDate, engagement.isEngaged, engagement.isRevoked);
    }
}
