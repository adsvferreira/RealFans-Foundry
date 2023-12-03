// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface ISoulboundBadges {
    function mintBadge(address to, string calldata badgeURI) external;

    function addNewBadgeURI(string memory badgeURI) external;

    function getAllURIs() external view returns (string[] memory);

    function getTokenIdCounter() external view returns (uint256);
}
