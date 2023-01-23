// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface Token {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(address, address, uint256) external;
}

contract WeeklyAuction {
    event Start(uint256 auctionNumber);
    event Bid(address indexed sender, uint256 amount);
    event End(address[] bidderList);
    Token public tokenToBeAttributed;
    uint256 public endAt;
    bool public started;
    bool public ended;
    string tokenID;
    address[] bidderList;
    address harmonia_eko;
    mapping(address => uint256) public bids;
    uint256 public totalBiddedAmount;
    uint256 public auctionNumber;
    

    constructor(
        address _tokenToBeAttributed,
        string memory _tokenID,
        address _harmonia_eko
    ) {
        tokenToBeAttributed = Token(_tokenToBeAttributed);
        tokenID = _tokenID;
        
        
        harmonia_eko
            = _harmonia_eko;
    }

    function start() public {
        require(!started, "started");
        require(msg.sender == harmonia_eko, "not authority");
        tokenToBeAttributed.transferFrom(msg.sender, address(this), 1);
        auctionNumber += 1;
        started = true;
        endAt = block.timestamp + 30 seconds;
        emit Start(auctionNumber);
    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        bids[msg.sender] += msg.value;
        totalBiddedAmount += msg.value;
        bidderList[bidderList.length + 1] = msg.sender;
        emit Bid(msg.sender, msg.value);
    }

    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");
        ended = true;
        if (bidderList.length != 0) {
            for (uint64 i = 0; i < bidderList.length; i++) {
                tokenToBeAttributed.safeTransferFrom(
                    address(this),
                    bidderList[i],
                    bids[bidderList[i]] /totalBiddedAmount
                );
            }
            tokenToBeAttributed.safeTransferFrom(address(this), harmonia_eko,totalBiddedAmount/100);
        }
        emit End(bidderList);
        start();
    }
}
