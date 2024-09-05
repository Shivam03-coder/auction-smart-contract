// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract IPL_AUCTION_SMART_CONTRACT {
    address payable public auctionManager;
    address payable public HighestAmountraiser;
    uint256 public stBlock;
    uint256 public etBlock;
    uint256 public HighestPayableAmount;
    uint256 public IncrementAmount;

    enum AuctionCurrentState {
        started,
        running,
        ending,
        cancel
    }

    AuctionCurrentState public AuctionState;

    mapping(address => uint256) public Amounts;

    constructor() {
        auctionManager = payable(msg.sender);
        stBlock = block.number;
        etBlock = stBlock + 240;
        AuctionState = AuctionCurrentState.running;
        IncrementAmount = 1 ether;
    }

    modifier onlyTeamOwner() {
        require(msg.sender != auctionManager, "Auction Manager Cannot bid");
        _;
    }

    modifier onlyAuctionManger() {
        require(
            msg.sender == auctionManager,
            "Only Auction Manager Can do this"
        );
        _;
    }

    modifier Started() {
        require(block.number > stBlock);
        _;
    }

    modifier beforeEnded() {
        require(block.number < etBlock);
        _;
    }

    modifier CancelAuction() {
        AuctionState = AuctionCurrentState.cancel;
        _;
    }

    modifier EndAuction() {
        AuctionState = AuctionCurrentState.ending;
        _;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        if (a <= b) {
            return a;
        } else return b;
    }

    function AuctionCancel() public onlyAuctionManger {
        AuctionState = AuctionCurrentState.cancel;
    }

    function Auction() public payable onlyTeamOwner Started beforeEnded {
        require(AuctionState == AuctionCurrentState.running);
        require(msg.value > 1 ether);

        uint256 currentAmount = Amounts[msg.sender] + msg.value;
        require(currentAmount > HighestPayableAmount);
        Amounts[msg.sender] = currentAmount;
        if (currentAmount < Amounts[HighestAmountraiser]) {
            HighestPayableAmount = min(
                currentAmount + IncrementAmount,
                Amounts[HighestAmountraiser]
            );
        } else {
            HighestPayableAmount = min(
                currentAmount,
                Amounts[HighestAmountraiser] + IncrementAmount
            );
            HighestAmountraiser = payable(msg.sender);
        }
    }

    function AuctionResult() public {
        require(
            AuctionState == AuctionCurrentState.cancel ||
                AuctionState == AuctionCurrentState.ending ||
                block.number > etBlock
        );

        require(msg.sender == auctionManager || Amounts[msg.sender] > 0);

        address payable person;
        uint256 value;

        if (AuctionState == AuctionCurrentState.cancel) {
            person = payable(msg.sender);
            value = Amounts[msg.sender];
        } else {
            if (msg.sender == auctionManager) {
                person = auctionManager;
                value = HighestPayableAmount;
            } else {
                if (msg.sender == HighestAmountraiser) {
                    person = HighestAmountraiser;
                    value = Amounts[HighestAmountraiser];
                } else {
                    person = payable(msg.sender);
                    value = Amounts[msg.sender];
                }
            }
        }

        Amounts[msg.sender] = 0;

        person.transfer(value);
    }
}
