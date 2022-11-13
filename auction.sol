//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;

contract SimpleAuction{
  struct Bidder{
    address bidderAddress;
    uint bid;
    bool hasWon;
    bool hasWithdrawed;
    bool transferred;
  }
  address payable public beneficiary;
  address payable public auctionOwner;
  address payable public highestBidder;
  uint public auctionEndTime;
  uint public highestBid;
  uint public minAssetValue;
  bool public hasEnded;
  mapping(address=>Bidder)public addressToBidder;
  //Initializing events
  event highestBidIncreased(uint indexed amount, address indexed bidder);
  event withdrawAmount(uint indexed amount, address indexed withdrawer ,bool hasWithdrawed);
  event amountToBenf(uint indexed amount, address indexed _benfAddr, address indexed _sender,bool transferred);
  //Initializing errors
  error auctionNotEndedYet();
  error auctionAlreadyEnded();
  error lessThanThreshold(string);
  error bidNotEnoughHigh(uint _highestBid);
  error authoritiesNotAllowed();
  error highestBidderCannotWithdraw(address _highestBidder);

  modifier onlyAuctionOwner(){
    require(msg.sender == auctionOwner);
    _;
  }
  constructor(address _beneficiary, uint _auctionTime, uint _minVal) {
    auctionOwner = payable(msg.sender);
    beneficiary = payable(_beneficiary);
    auctionEndTime = block.timestamp + _auctionTime;
    minAssetValue = _minVal;
    } 

  //make function to bid
  function bid() public payable{
    Bidder storage _bidder = addressToBidder[msg.sender];
    if(block.timestamp>auctionEndTime){
     revert auctionAlreadyEnded();
    }
    if(msg.value<minAssetValue){
      revert lessThanThreshold("Amount should not be less than minimum Asset Value");
    }
    if(msg.value<highestBid){
     revert bidNotEnoughHigh(highestBid);
    }
    if(msg.sender == beneficiary && msg.sender == auctionOwner){
      revert authoritiesNotAllowed();
    }
    _bidder.bidderAddress = msg.sender;
    _bidder.bid = msg.value;
    highestBid = msg.value;
    highestBidder = payable(msg.sender);
    emit highestBidIncreased(msg.value, msg.sender);
  }
  //make withdraw function
  function withdraw() external payable{
   if(msg.sender == beneficiary && msg.sender == auctionOwner){
      revert authoritiesNotAllowed();
    }
   if(msg.sender == highestBidder){
     revert highestBidderCannotWithdraw(msg.sender);
   } 
   if(block.timestamp<auctionEndTime){
     revert auctionNotEndedYet();
   }
   Bidder storage _bidder = addressToBidder[msg.sender];
   uint bal = _bidder.bid;
   payable(msg.sender).transfer(bal);
   bal = 0;//This is done to avoid re-entrancy attack...
   _bidder.hasWithdrawed = true;
   emit withdrawAmount(bal,msg.sender, true);
  }
  //make function to transfer highest amount to beneficiary
  function endAuction() external onlyAuctionOwner{
    if(block.timestamp<auctionEndTime){
     revert auctionNotEndedYet();
   }
   addressToBidder[highestBidder].hasWon = true;
   beneficiary.transfer(highestBid);
   addressToBidder[highestBidder].transferred = true;
   emit amountToBenf(highestBid,beneficiary,msg.sender,true);
   highestBid = 0;
   hasEnded = true;
  }

}
