// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ISoulboundBadges} from "../interfaces/ISoulboundBadges.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract SoulboundBadges is ERC721, ERC721URIStorage, Ownable, ISoulboundBadges {
    ///////////////////
    // Errors
    ///////////////////
    error SoulboundBadges__TokenURINotWhitelisted();
    error SoulboundBadges__TokenAlreadyWhitelisted();
    error SoulboundBadges__TokenNotTransferable();

    ///////////////////
    // Types
    ///////////////////
    using Strings for string;

    ///////////////////
    // State Variables
    ///////////////////
    string[] private _badgeURIs;
    uint256 private _tokenIdCounter;

    mapping(string => uint256) private _totalBadgeQty;
    mapping(address => mapping(string => uint256)) private _badgeQtyPerAddress;

    event BadgeMinted(address indexed receiver, string badgeURI);

    constructor() ERC721("SoulboundBadges", "SBB") Ownable(msg.sender) {}

    function mintBadge(address to, string calldata badgeURI) external onlyOwner {
        if (!_isBadgeURIWhitelisted(badgeURI)) {
            revert SoulboundBadges__TokenURINotWhitelisted();
        }
        uint256 tokenIdCounter = _tokenIdCounter + 1;
        _safeMint(to, tokenIdCounter);
        _setTokenURI(tokenIdCounter, badgeURI);
        _tokenIdCounter = tokenIdCounter;
        ++_totalBadgeQty[badgeURI];
        ++_badgeQtyPerAddress[to][badgeURI];
        emit BadgeMinted(to, badgeURI);
    }

    function addNewBadgeURI(string memory badgeURI) external onlyOwner {
        if (_isBadgeURIWhitelisted(badgeURI)) {
            revert SoulboundBadges__TokenAlreadyWhitelisted();
        }
        _badgeURIs.push(badgeURI);
    }

    function _isBadgeURIWhitelisted(string memory badgeURI) private view returns (bool) {
        string[] memory badgeURIs = _badgeURIs;
        uint256 badgeURIsLength = badgeURIs.length;
        for (uint256 i = 0; i < badgeURIsLength;) {
            if (badgeURI.equal(badgeURIs[i])) {
                return true;
            }
            unchecked {
                ++i;
            }
        }
        return false;
    }

    function getAllURIs() external view returns (string[] memory) {
        return _badgeURIs;
    }

    function getTokenIdCounter() external view returns (uint256) {
        return _tokenIdCounter;
    }

    function getTotalQtyOfBadge(string memory badgeURI) public view returns (uint256 totalSupply) {
        totalSupply = _totalBadgeQty[badgeURI];
    }

    function getBadgeQtyOf(address account, string memory badgeURI) public view returns (uint256 badgeQtyOf) {
        badgeQtyOf = _badgeQtyPerAddress[account][badgeURI];
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

    /**
     * @dev Transfers `tokenId` from its current owner to `to`, or alternatively mints (or burns) if the current owner
     * (or `to`) is the zero address. Returns the owner of the `tokenId` before the update.
     *
     * The `auth` argument is optional. If the value passed is non 0, then this function will check that
     * `auth` is either the owner of the token, or approved to operate on the token (by the owner).
     *
     * Emits a {Transfer} event.
     *
     * NOTE: If overriding this function in a way that tracks balances, see also {_increaseBalance}.
     */
    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        {
            if (from != address(0)) {
                revert SoulboundBadges__TokenNotTransferable();
            }
            super._update(to, tokenId, address(0));
        }
    }
}
