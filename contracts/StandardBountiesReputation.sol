pragma solidity ^0.4.18;
import './StandardBounties.sol';

contract StandardBountiesReputation is StandardBounties {

    struct BountyHistory {
        uint totalIssued;
        uint totalFulfillmentsSubmitted;
        uint totalIssuesSolved;
    }

    modifier validateTotalIssued(address _issuer) {
        require(history[_issuer].totalIssued + 1 > history[_issuer].totalIssued);
        _;
    }

    modifier validateTotalFulfillmentsSubmitted(address _issuer) {
        require(history[_issuer].totalFulfillmentsSubmitted + 1 > history[_issuer].totalFulfillmentsSubmitted);
        _;
    }

    modifier validateTotalIssuesResolved(address _issuer) {
        require(history[_issuer].totalIssuesSolved + 1 > history[_issuer].totalIssuesSolved);
        _;
    }

    mapping (address => BountyHistory) history;

    uint totalIssuedWeight;
    uint totalFulfillmentsSubmittedWeight;
    uint totalIssuesSolvedWeight;

    function StandardBountiesReputation(
        address _owner,
        uint _totalIssuedWeight,
        uint _totalFulfillmentsSubmittedWeight,
        uint _totalIssuesSolvedWeight
    )
    public
    StandardBounties(_owner)
    {
        totalIssuedWeight = _totalIssuedWeight;
        totalFulfillmentsSubmittedWeight = _totalFulfillmentsSubmittedWeight;
        totalIssuesSolvedWeight = _totalIssuesSolvedWeight;
    }





    function issueBounty(
        address _issuer,
        uint _deadline,
        string _data,
        uint256 _fulfillmentAmount,
        address _arbiter,
        bool _paysTokens,
        address _tokenContract
    )
    public
    validateDeadline(_deadline)
    amountIsNotZero(_fulfillmentAmount)
    validateNotTooManyBounties
    validateTotalIssued
    returns (uint)
    {
        history[_issuer].totalIssued += 1;
        super.issueBounty(_issuer, _deadline, _data, _fulfillmentAmount, _arbiter, _paysTokens, _tokenContract);
    }





    function issueAndActivateBounty(
        address _issuer,
        uint _deadline,
        string _data,
        uint256 _fulfillmentAmount,
        address _arbiter,
        bool _paysTokens,
        address _tokenContract,
        uint256 _value
    )
    public
    payable
    validateDeadline(_deadline)
    amountIsNotZero(_fulfillmentAmount)
    validateNotTooManyBounties
    returns (uint)
    {
        history[_issuer].totalIssued += 1;
        super.issueAndActivateBounty(_issuer, _deadline, _data, _fulfillmentAmount, _arbiter, _paysTokens, _tokenContract, _value);
    }




    function fulfillBounty(
        uint _bountyId,
        string _data
    )
    public
    validateBountyArrayIndex(_bountyId)
    validateNotTooManyFulfillments(_bountyId)
    isAtStage(_bountyId, BountyStages.Active)
    isBeforeDeadline(_bountyId)
    notIssuerOrArbiter(_bountyId)
    validateTotalFulfillmentsSubmitted
    {
        history[msg.sender].totalFulfillmentsSubmitted += 1;
        super.fulfillBounty(_bountyId, _data);
    }




    function acceptFulfillment(
        uint _bountyId,
        uint _fulfillmentId
    )
    public
    validateBountyArrayIndex(_bountyId)
    validateFulfillmentArrayIndex(_bountyId, _fulfillmentId)
    onlyIssuerOrArbiter(_bountyId)
    isAtStage(_bountyId, BountyStages.Active)
    fulfillmentNotYetAccepted(_bountyId, _fulfillmentId)
    enoughFundsToPay(_bountyId)
    validateTotalIssuesResolved
    {
        address fulfiller = fulfillments[_bountyId][_fulfillmentId].fulfiller;
        history[fulfiller].totalIssuesResolved += 1;
        super.acceptFulfillment(_bountyId, _fulfillmentId);
    }




    function getReputation(address _user) public returns (uint, uint, uint, uint) {
        BountyHistory storage user = history[_user];

        uint totalIssuedReputation = user.totalIssued * totalIssuedWeight;
        uint totalFulfillmentsSubmittedReputation = user.totalFulfillmentsSubmitted * totalFulfillmentsSubmittedWeight;
        uint totalIssuesResolvedReputation = user.totalIssuesResolved * totalIssuesResolvedWeight;

        uint totalReputation = totalIssuedReputation + totalFulfillmentsSubmittedReputation + totalIssuesResolvedReputation;

        return (
            totalIssuedReputation,
            totalFulfillmentsSubmittedReputation,
            totalIssuesResolvedReputation,
            totalReputation
        );
    }
}