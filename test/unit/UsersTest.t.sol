// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Users} from "../../src/protocol/Users.sol";
import {NFTGifts} from "../../src/protocol/NFTGifts.sol";
import {DeployRealFans} from "../../script/Deploy.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StdCheats} from "../../lib/forge-std/src/StdCheats.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CommunityVault} from "../../src/protocol/CommunityVault.sol";
import {SoulboundBadges} from "../../src/protocol/SoulboundBadges.sol";

contract UsersTest is StdCheats, Test {
    Users users;
    address user = address(1);
    string userHandle = "1DeadPixel";

    function setUp() public {
        DeployRealFans deployer = new DeployRealFans();
        SoulboundBadges sbb;
        CommunityVault communityVault;
        NFTGifts nftGifts;
        HelperConfig helperConfig;
        (sbb, users, communityVault, nftGifts, helperConfig) = deployer.run();
    }

    function testOwnerCanWriteTwitterhandle() public {
        address initialAddressFromHandle = users.getAddressFromTwitterHandle(userHandle);
        string memory initialHandleFromAddress = users.getTwitterHandleFromAddress(user);
        _addTwitterHandler();
        address finalAddressFromHandle = users.getAddressFromTwitterHandle(userHandle);
        string memory finalHandleFromAddress = users.getTwitterHandleFromAddress(user);
        string memory emptyString = "";
        assertEq(initialHandleFromAddress, emptyString);
        assertEq(initialAddressFromHandle, address(0));
        assertEq(finalHandleFromAddress, userHandle);
        assertEq(finalAddressFromHandle, user);
    }

    function testRevertIfAddressAlreadyHasHandle() public {
        _addTwitterHandler();
        address owner = users.owner();
        string memory newHandle = "newHandle";
        vm.startPrank(owner);
        vm.expectRevert("Already associated address");
        users.writeTwitterHandle(user, newHandle);
        vm.stopPrank();
    }

    function testRevertIfHandleosAlreadyUsed() public {
        _addTwitterHandler();
        address owner = users.owner();
        vm.startPrank(owner);
        vm.expectRevert("Already associated Twitter Handle");
        users.writeTwitterHandle(owner, userHandle);
        vm.stopPrank();
    }

    function testRevertIfWriteTwitterHandleIsCalledByNonOwner() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        users.writeTwitterHandle(user, userHandle);
        vm.stopPrank();
    }

    function _addTwitterHandler() private {
        address owner = users.owner();
        vm.startPrank(owner);
        users.writeTwitterHandle(user, userHandle);
        vm.stopPrank();
    }
}
