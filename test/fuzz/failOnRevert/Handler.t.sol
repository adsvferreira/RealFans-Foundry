//SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Users} from "../../../src/protocol/Users.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {Test, console} from "../../../lib/forge-std/src/Test.sol";
import {SoulboundBadges} from "../../../src/protocol/SoulboundBadges.sol";

contract Handler is Test {
    Users users;
    SoulboundBadges sbb;

    mapping(address user => bool) public isUserAdded;
    mapping(string handle => bool) public isHandleAdded;
    mapping(string uri => bool) public isUriAdded;

    constructor(Users _users, SoulboundBadges _sbb) {
        users = _users;
        sbb = _sbb;
    }

    function writeTwitterHandle(address userAddress, string calldata twitterHandle) public {
        if (isUserAdded[userAddress] == true || isHandleAdded[twitterHandle] == true) {
            return;
        }
        address owner = users.owner();
        vm.startPrank(owner);
        users.writeTwitterHandle(userAddress, twitterHandle);
        vm.stopPrank();
        isUserAdded[userAddress] = true;
        isHandleAdded[twitterHandle] = true;
    }

    function addNewBadgeURIandMintBadge(address to, string calldata badgeURI) public {
        if (to == address(0) || bytes(badgeURI).length == 0 || isUriAdded[badgeURI] == true) {
            return;
        }
        address owner = sbb.owner();
        vm.startPrank(owner);
        sbb.addNewBadgeURI(badgeURI);
        sbb.mintBadge(to, badgeURI);
        vm.stopPrank();
        isUriAdded[badgeURI] = true;
    }
}
