// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
import "./ExpiryHelper.sol";
// import "../../hedera-smart-contracts/contracts/safe-hts-precompile/HederaTokenService.SafeHTS.sol";
contract KarbonMoneta is ExpiryHelper {
    
    event Start(uint256 auctionNumber);
    event Bid(address indexed sender, uint256 amount);
    event End(address[] bidderList);
    uint256 public endAt;
    bool public started;
    bool public ended;
    address tokenAddress;
    address[] bidderList;
    address corporateAddress;
    mapping(address => uint256) public bids;
    uint256 public totalBiddedAmount;
    uint256 public auctionNumber;
  constructor() {
        corporateAddress = msg.sender;
        IHederaTokenService.Expiry memory expiry =ExpiryHelper.createAutoRenewExpiry(corporateAddress, 7776000);
IHederaTokenService.TokenKey[]memory keys = new IHederaTokenService.TokenKey[](2);
            
        // Set this contract as supply
        keys[0] =HederaTokenService.SafeHTS.getSingleKey(
            KeyType.SUPPLY,
            HederaTokenService.KeyValueType.CONTRACT_ID,
            address(this)
        );
        keys[1] = HederaTokenService.SafeHTS.getSingleKey(
            HederaTokenService.SafeHTS.KeyType.ADMIN,
            HederaTokenService.SafeHTS.KeyValueType.INHERIT_ACCOUNT_KEY,
            corporateAddress
        );



    IHederaTokenService.HederaToken calldata token= IHederaTokenService.HederaToken({name:"Karbon Moneta",memo:"The proof of carbon removal currency",symbol:"KM",tokenSupplyType:true,maxSupply:5000000000,freezeDefault:false,expiry:expiry,tokenKeys:keys,treasury:address(this)});
        tokenAddress=HederaTokenService.SafeHTS.safeCreateFungibleToken(token,1100000000000000,8);
    }

    function start() public {
        require(!started, "started");
        require(msg.sender == corporateAddress, "not authority");
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
        HederaTokenService.SafeHTS.safeMintToken(tokenAddress,100000000,new bytes[]);
        if (bidderList.length != 0) {
            for (uint64 i = 0; i < bidderList.length; i++) {
                HederaTokenService.SafeHTS.safeTransferToken(
                    address(this),
                    bidderList[i],
                    bids[bidderList[i]] / totalBiddedAmount
                );
            }
            HederaTokenService.SafeHTS.safeTransferFrom(
                address(this),
                corporateAddress,
                totalBiddedAmount / 100
            );
        }
        emit End(bidderList);
        start();
    }
}
