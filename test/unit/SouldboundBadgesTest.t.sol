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

contract SoulboundBadgesTest is StdCheats, Test {
    SoulboundBadges sbb;
    string[] public soulboundUris;
    HelperConfig.NetworkConfig networkConfig;
    address user = address(1);

    function setUp() public {
        DeployRealFans deployer = new DeployRealFans();
        Users users;
        CommunityVault communityVault;
        NFTGifts nftGifts;
        HelperConfig helperConfig;
        soulboundUris = [
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/TheGiftofGifting.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/ThePatron.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/Philanthropist.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/DoubleTrouble.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/FiveofaKind.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/TheDecadeofGiving.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/Fan.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/TheLoyalSupporter.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/TheDecadeofDevotion.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/TheSpendingSpree.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/TheFinancialOdyssey.json",
            "https://ipfs.io/ipfs/bafybeicxnf7sgyjxeky52vbxh3csltzfhat2bczli37v4qczi24i6xvkiq/TheGrandioseWealthVenture.json",
            "https://ipfs.io/ipfs/bafybeibcqxyc4ufkmexrhi6wu2s7qc3thizng3zcjqgtgyqct6x4i4debu"
        ];
        (sbb, users, communityVault, nftGifts, helperConfig) = deployer.run();
        networkConfig = helperConfig.getActiveNetworkConfig();
    }

    modifier addBadgeUris() {
        uint256 soulboundUrisLength = soulboundUris.length;
        vm.startPrank(sbb.owner());
        for (uint256 i = 0; i < soulboundUrisLength; i++) {
            sbb.addNewBadgeURI(soulboundUris[i]);
        }
        vm.stopPrank();
        _;
    }

    function testOwnerCanAddBadgeUris() public addBadgeUris {
        uint256 addedURIsLength = sbb.getAllURIs().length;
        assertEq(addedURIsLength, soulboundUris.length);
    }

    function testOwnerCanMintBadge() public addBadgeUris {
        address owner = sbb.owner();
        string memory uri = soulboundUris[0];
        uint256 initialBadgeCount = sbb.getTotalQtyOfBadge(uri);
        uint256 initialWalletBadgeCount = sbb.getBadgeQtyOf(owner, uri);
        uint256 initialTokenIdCounter = sbb.getTokenIdCounter();
        vm.startPrank(owner);
        sbb.mintBadge(owner, uri);
        vm.stopPrank();
        uint256 finalBadgeCount = sbb.getTotalQtyOfBadge(uri);
        uint256 finalWalletBadgeCount = sbb.getBadgeQtyOf(owner, uri);
        uint256 finalTokenIdCounter = sbb.getTokenIdCounter();
        assertEq(finalBadgeCount, initialBadgeCount + 1);
        assertEq(finalWalletBadgeCount, initialWalletBadgeCount + 1);
        assertEq(finalTokenIdCounter, initialTokenIdCounter + 1);
    }

    function testRevertIfAddedBadgeUrlWasAlreadyAdded() public addBadgeUris {
        string memory uri = soulboundUris[0];
        vm.startPrank(sbb.owner());
        vm.expectRevert(SoulboundBadges.SoulboundBadges__TokenAlreadyWhitelisted.selector);
        sbb.addNewBadgeURI(uri);
        vm.stopPrank();
    }

    function testRevertIfUriIsAddedByNonOwner() public {
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        sbb.addNewBadgeURI(soulboundUris[0]);
        vm.stopPrank();
    }

    function testRevertIfMintedURIisNotWhitelisted() public addBadgeUris {
        string memory invalidUri = "https://test_uri.json";
        address owner = sbb.owner();
        vm.startPrank(owner);
        vm.expectRevert(SoulboundBadges.SoulboundBadges__TokenURINotWhitelisted.selector);
        sbb.mintBadge(owner, invalidUri);
        vm.stopPrank();
    }

    function testRevertIfMinterIsNotOwner() public addBadgeUris {
        string memory uri = soulboundUris[0];
        vm.startPrank(user);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, user));
        sbb.mintBadge(user, uri);
        vm.stopPrank();
    }

    function testRevertOnBadgeTransfer() public addBadgeUris {
        address owner = sbb.owner();
        string memory uri = soulboundUris[0];
        vm.startPrank(owner);
        sbb.mintBadge(owner, uri);
        vm.expectRevert(SoulboundBadges.SoulboundBadges__TokenNotTransferable.selector);
        uint256 token_id = 1;
        sbb.transferFrom(owner, user, token_id);
        vm.stopPrank();
    }
}
