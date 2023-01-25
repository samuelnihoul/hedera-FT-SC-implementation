// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;
import "../Auction2/hts-precompile/HederaResponseCodes.sol";
import "../Auction2/hts-precompile/IHederaTokenService.sol";
import "../Auction2/hts-precompile/HederaTokenService.sol";
import "../Auction2/hts-precompile/KeyHelper.sol";
import "../Auction2/hts-precompile/ExpiryHelper.sol";
error FailedToCreateNFT (int errorCode);
contract NFTCreator is ExpiryHelper, HederaTokenService {
    
    function createNft(
        string memory name,
        string memory symbol,
        string memory memo,
        uint32 maxSupply,
        uint32 autoRenewPeriod
    ) external payable returns (address) {
        
        IHederaTokenService.TokenKey[]
            memory keys = new IHederaTokenService.TokenKey[](1);
        // Set this contract as supply
        keys[0] = getSingleKey(
            KeyType.SUPPLY,
            KeyValueType.CONTRACT_ID,
            address(this)
        );

        IHederaTokenService.HederaToken memory token;
        token.name = name;
        token.symbol = symbol;
        token.memo = memo;
        token.treasury = address(this);
        token.tokenSupplyType = true; // set supply to FINITE
        token.maxSupply = maxSupply;
        token.tokenKeys = keys;
        token.freezeDefault = false;
        token.expiry = createAutoRenewExpiry(address(this), autoRenewPeriod); // Contract automatically renew by himself

        (int responseCode, address createdToken) = HederaTokenService
            .createNonFungibleToken(token);

        if (responseCode != HederaResponseCodes.SUCCESS) {
             revert FailedToCreateNFT(responseCode) 
        }
        return createdToken;
    }

    function mintNft(
        address token,
        bytes[] memory metadata
    ) external returns (int64) {
        (int response, , int64[] memory serial) = HederaTokenService.mintToken(
            token,
            0,
            metadata
        );

        if (response != HederaResponseCodes.SUCCESS) {
            revert("Failed to mint non-fungible token");
        }

        return serial[0];
    }

    function transferNft(
        address token,
        address receiver,
        int64 serial
    ) external returns (int) {
        HederaTokenService.associateToken(receiver, token);
        int response = HederaTokenService.transferNFT(
            token,
            address(this),
            receiver,
            serial
        );

        if (response != HederaResponseCodes.SUCCESS) {
            revert("Failed to transfer non-fungible token");
        }

        return response;
    }
}