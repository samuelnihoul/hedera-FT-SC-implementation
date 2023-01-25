// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "../../hedera-smart-contracts/contracts/safe-hts-precompile/SafeHTS.sol";



contract KarbonMoneta is SafeHTS {
    event Start(uint256 auctionNumber);
    event Bid(address indexed sender, uint256 amount);
    event End(address[] bidderList);
    Token public token;
    uint256 public endAt;
    bool public started;
    bool public ended;
    string tokenID;
    address[] bidderList;
    address corporateAddress;
    mapping(address => uint256) public bids;
    uint256 public totalBiddedAmount;
    uint256 public auctionNumber;

    constructor() {
        corporateAddress = msg.sender;
    }

    function createToken() public {
        IHederaTokenService.HederaToken _token= IHederaTokenService.HederaToken(name:'Karbon Moneta',symbol:'KM',treasury:corporateAddress)
        require(msg.sender == corporateAddress, "not authority");
        safeCreateFungibleToken(token)
    }

    function start() public {
        require(!started, "started");
        require(msg.sender == corporateAddress, "not authority");
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
                    bids[bidderList[i]] / totalBiddedAmount
                );
            }
            tokenToBeAttributed.safeTransferFrom(
                address(this),
                corporateAddress,
                totalBiddedAmount / 100
            );
        }
        emit End(bidderList);
        start();
    }
}
