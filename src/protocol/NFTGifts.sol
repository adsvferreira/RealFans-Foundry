// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Users} from "./Users.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {INFTGifts} from "../interfaces/INFTGifts.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {CommunityVault, IERC20} from "./CommunityVault.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NFTGifts is ERC721, ERC721URIStorage, Ownable, INFTGifts {
    using Strings for string;
    using SafeERC20 for IERC20;

    CommunityVault communityVault;
    Users usersDB;

    string[] private _giftURIs;
    uint256 private _tokenIdCounter;
    address[] private _donators;
    address[] private _receivers;
    string[] private _unclaimedAccountReceivers;

    mapping(uint256 => bool) private _isRedeemed;
    mapping(string => uint256) private _totalGiftQty;
    mapping(string => uint256) private _ethValuePerGiftURI;
    mapping(address => mapping(string => uint256)) private _GiftQtyPerAddress;
    mapping(address => mapping(string => uint256)) private _DonatedQtyPerAddress;
    mapping(string => mapping(string => uint256)) private _balancesUnclaimedAccounts;

    event Donation(
        address indexed donator,
        address indexed receiver,
        string receiverTwitterHandle,
        string donatorTwitterHandle,
        string giftURI,
        uint256 ethValue
    );

    event Redemption(address indexed receiver, string receiverTwitterHandle, string giftURI, uint256 ethValue);

    constructor(address _vaultAddress, address _usersAddress) ERC721("NFTGifts", "NFTG") Ownable(msg.sender) {
        communityVault = CommunityVault(_vaultAddress);
        usersDB = Users(_usersAddress);
    }

    function mintGift(string memory receiverTwitterHandle, string calldata giftURI) external {
        require(_isGiftURIWhitelisted(giftURI), "tokenURI noy whitelisted yet");
        address to = usersDB.getAddressFromTwitterHandle(receiverTwitterHandle);
        uint256 ethValue = _ethValuePerGiftURI[giftURI];
        address depositAsset = communityVault.asset();
        string memory donatorTwitterHandle = usersDB.getTwitterHandleFromAddress(msg.sender);

        if (to != address(0)) {
            uint256 newTokenIdCounter = _tokenIdCounter + 1;
            _safeMint(to, newTokenIdCounter);
            _setTokenURI(newTokenIdCounter, giftURI);
            _isRedeemed[newTokenIdCounter] = false;
            _tokenIdCounter = newTokenIdCounter;
            _updateReceiversList(to);
            ++_GiftQtyPerAddress[to][giftURI];
        } else {
            _updateUnclaimedReceiversList(receiverTwitterHandle);
            ++_balancesUnclaimedAccounts[receiverTwitterHandle][giftURI];
        }
        SafeERC20.safeTransferFrom(IERC20(depositAsset), msg.sender, address(this), ethValue);
        IERC20(depositAsset).approve(address(communityVault), ethValue);
        communityVault.deposit(ethValue, address(this));
        _updateDonatorsList(msg.sender);
        ++_DonatedQtyPerAddress[to][giftURI];
        ++_totalGiftQty[giftURI];
        emit Donation(msg.sender, to, receiverTwitterHandle, donatorTwitterHandle, giftURI, ethValue);
    }

    function addNewGiftURI(string memory giftURI, uint256 ethValue) external onlyOwner {
        require(!_isGiftURIWhitelisted(giftURI), "tokenURI already whitelisted");
        _giftURIs.push(giftURI);
        _ethValuePerGiftURI[giftURI] = ethValue;
    }

    function redeemDonation(uint256 tokenId) public {
        require(msg.sender == ownerOf(tokenId), "Forbidden");
        string memory giftTokenURI = tokenURI(tokenId);
        uint256 ethValue = _ethValuePerGiftURI[giftTokenURI];
        string memory receiverTwitterHandle = usersDB.getTwitterHandleFromAddress(msg.sender);
        _isRedeemed[tokenId] = true;
        communityVault.withdraw(ethValue, msg.sender, address(this));
        emit Redemption(msg.sender, receiverTwitterHandle, giftTokenURI, ethValue);
    }

    function redeemDonationsToUnclaimedAccount(string memory giftURI) external {
        address to = msg.sender;
        string memory toHandler = usersDB.getTwitterHandleFromAddress(to);

        require(!toHandler.equal(""), "Twitter handle not yet claimed");

        string memory receiverTwitterHandle = usersDB.getTwitterHandleFromAddress(to);
        uint256 giftQtyToReceive = _balancesUnclaimedAccounts[receiverTwitterHandle][giftURI];

        require(giftQtyToReceive != 0, "Insufficient balance");

        _updateReceiversList(to);
        ++_GiftQtyPerAddress[to][giftURI];

        for (uint256 i = 0; i < giftQtyToReceive;) {
            uint256 newTokenIdCounter = _tokenIdCounter + 1;
            _tokenIdCounter = newTokenIdCounter;
            _safeMint(to, newTokenIdCounter);
            _setTokenURI(newTokenIdCounter, giftURI);

            redeemDonation(newTokenIdCounter);

            _isRedeemed[newTokenIdCounter] = true;
            --_balancesUnclaimedAccounts[receiverTwitterHandle][giftURI];

            unchecked {
                ++i;
            }
        }
    }

    function isRedeemed(uint256 tokenId) external view returns (bool) {
        return _isRedeemed[tokenId];
    }

    function getAllURIs() external view returns (string[] memory) {
        return _giftURIs;
    }

    function getTokenIdCounter() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function getEthValueOfGift(string memory giftURI) public view returns (uint256 ethValue) {
        ethValue = _ethValuePerGiftURI[giftURI];
    }

    function getTotalQtyOfGift(string memory giftURI) public view returns (uint256 totalSupply) {
        totalSupply = _totalGiftQty[giftURI];
    }

    function getGiftQtyOf(address account, string memory giftURI) public view returns (uint256 giftQtyOf) {
        giftQtyOf = _GiftQtyPerAddress[account][giftURI];
    }

    function getEthBalanceOfPerGift(address account, string memory giftURI)
        public
        view
        returns (uint256 ethBalanceOfPerGift)
    {
        ethBalanceOfPerGift = getGiftQtyOf(account, giftURI) * getEthValueOfGift(giftURI);
    }

    function getEthBalanceOf(address account) external view returns (uint256 ethBalanceOf) {
        string[] memory giftURIs = _giftURIs;
        uint256 giftURIsLength = giftURIs.length;
        for (uint256 i = 0; i < giftURIsLength;) {
            ethBalanceOf += getEthBalanceOfPerGift(account, giftURIs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getTotalEthBalance() external view returns (uint256 totalEthBalance) {
        string[] memory giftURIs = _giftURIs;
        uint256 giftURIsLength = giftURIs.length;
        for (uint256 i = 0; i < giftURIsLength;) {
            totalEthBalance += getTotalQtyOfGift(giftURIs[i]) * getEthValueOfGift(giftURIs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function getAllDonators() external view returns (address[] memory) {
        return _donators;
    }

    function getAllUnclaimedAccountReceivers() external view returns (string[] memory) {
        return _unclaimedAccountReceivers;
    }

    function getAllReceivers() external view returns (address[] memory) {
        return _receivers;
    }

    function getGiftQtyOfUnclaimedAccount(string memory twitterHandle, string memory giftURI)
        public
        view
        returns (uint256 giftQtyOf)
    {
        return _balancesUnclaimedAccounts[twitterHandle][giftURI];
    }

    function getDonatedQtyOf(address donator, string memory giftURI) public view returns (uint256 giftQtyOf) {
        return _DonatedQtyPerAddress[donator][giftURI];
    }

    function getEthBalanceOfPerGiftUnclaimedAccount(string memory twitterHandle, string memory giftURI)
        public
        view
        returns (uint256 ethBalanceOfPerGift)
    {
        ethBalanceOfPerGift = getGiftQtyOfUnclaimedAccount(twitterHandle, giftURI) * getEthValueOfGift(giftURI);
    }

    function getEthBalanceOfUnclaimedAccount(string memory twitterHandle)
        external
        view
        returns (uint256 ethBalanceOf)
    {
        string[] memory giftURIs = _giftURIs;
        uint256 giftURIsLength = giftURIs.length;
        for (uint256 i = 0; i < giftURIsLength;) {
            ethBalanceOf += getEthBalanceOfPerGiftUnclaimedAccount(twitterHandle, giftURIs[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _isGiftURIWhitelisted(string memory giftURI) private view returns (bool) {
        string[] memory giftURIs = _giftURIs;
        uint256 giftURIsLength = giftURIs.length;
        for (uint256 i = 0; i < giftURIsLength;) {
            if (giftURI.equal(giftURIs[i])) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function _updateDonatorsList(address donator) private {
        string[] memory giftURIs = _giftURIs;
        uint256 giftURIsLength = giftURIs.length;
        bool isFirstDonation = true;
        for (uint256 i = 0; i < giftURIsLength;) {
            if (_DonatedQtyPerAddress[donator][giftURIs[i]] != 0) {
                isFirstDonation = false;
            }
            unchecked {
                ++i;
            }
        }
        if (isFirstDonation) {
            _donators.push(donator);
        }
    }

    function _updateReceiversList(address receiver) private {
        string[] memory giftURIs = _giftURIs;
        uint256 giftURIsLength = giftURIs.length;
        bool isFirstDonation = true;
        for (uint256 i = 0; i < giftURIsLength;) {
            if (_GiftQtyPerAddress[receiver][giftURIs[i]] != 0) {
                isFirstDonation = false;
            }
            unchecked {
                ++i;
            }
        }
        if (isFirstDonation) {
            _receivers.push(receiver);
        }
    }

    function _updateUnclaimedReceiversList(string memory receiverTwitterHandle) private {
        string[] memory giftURIs = _giftURIs;
        uint256 giftURIsLength = giftURIs.length;
        bool isFirstDonation = true;
        for (uint256 i = 0; i < giftURIsLength;) {
            if (_balancesUnclaimedAccounts[receiverTwitterHandle][giftURIs[i]] != 0) {
                isFirstDonation = false;
            }
            unchecked {
                ++i;
            }
        }
        if (isFirstDonation) {
            _unclaimedAccountReceivers.push(receiverTwitterHandle);
        }
    }

    // The following functions are overrides required by Solidity:

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
