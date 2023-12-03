// SPDX-License-Identifier: MIT

pragma solidity 0.8.21;

import {Handler} from "./Handler.t.sol";
import {Users} from "../../../src/protocol/Users.sol";
import {StdInvariant} from "forge-std/StdInvariant.sol";
import {NFTGifts} from "../../../src/protocol/NFTGifts.sol";
import {DeployRealFans} from "../../../script/Deploy.s.sol";
import {HelperConfig} from "../../../script/HelperConfig.s.sol";
import {Test, console} from "../../../lib/forge-std/src/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {CommunityVault} from "../../../src/protocol/CommunityVault.sol";
import {SoulboundBadges} from "../../../src/protocol/SoulboundBadges.sol";

contract InvariantsTest is StdInvariant, Test {
    Handler handler;
    Users users;
    SoulboundBadges sbb;

    function setUp() public {
        DeployRealFans deployer = new DeployRealFans();
        CommunityVault communityVault;
        NFTGifts nftGifts;
        HelperConfig helperConfig;
        (sbb, users, communityVault, nftGifts, helperConfig) = deployer.run();
        handler = new Handler(users, sbb);
        targetContract(address(handler));
    }

    // This test is quite simple, but it forces the execution of all Handler functions in many random sequences with random inputs.
    // The execution of this test with `fail_on_revert` = true forces the developer to include guard clauses in the handler
    // for all the cases where called functions are expected revert.
    // Great way to find unexpected edge cases.
    function invariant_gettersWithoutParametersCantRevert() public view {
        sbb.getAllURIs();
        sbb.getTokenIdCounter();
    }
}
