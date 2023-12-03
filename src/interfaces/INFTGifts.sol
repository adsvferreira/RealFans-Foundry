// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface INFTGifts {
    function mintGift(string memory receiverTwitterHandle, string calldata badgeURI) external;

    function addNewGiftURI(string memory badgeURI, uint256 ethValue) external;

    function redeemDonationsToUnclaimedAccount(string memory giftURI) external;

    function isRedeemed(uint256 tokenId) external view returns (bool);

    function getAllURIs() external view returns (string[] memory);

    function getTokenIdCounter() external view returns (uint256);

    function getEthBalanceOf(address account) external view returns (uint256 ethBalanceOf);

    function getTotalEthBalance() external view returns (uint256 totalEthBalance);

    function getAllDonators() external view returns (address[] memory);

    function getAllUnclaimedAccountReceivers() external view returns (string[] memory);

    function getAllReceivers() external view returns (address[] memory);

    function getEthBalanceOfUnclaimedAccount(string memory twitterHandle)
        external
        view
        returns (uint256 ethBalanceOf);
}
