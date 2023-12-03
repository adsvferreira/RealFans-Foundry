// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";
import {Users} from "../src/protocol/Users.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {NFTGifts} from "../src/protocol/NFTGifts.sol";
import {CommunityVault} from "../src/protocol/CommunityVault.sol";
import {SoulboundBadges} from "../src/protocol/SoulboundBadges.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployRealFans is Script {
    address public depositTokenAddress;

    function run() external returns (SoulboundBadges, Users, CommunityVault, NFTGifts, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig(); // Comment this line when deploying to public networks or HelperConfig will be deployed.

        (address weth, string memory vaultName, string memory vaultSymbol, uint256 deployerKey) =
            helperConfig.activeNetworkConfig();
        depositTokenAddress = weth;

        vm.startBroadcast(deployerKey);
        SoulboundBadges soulboundBadges = new SoulboundBadges();
        Users users = new Users();
        CommunityVault communityVault = new CommunityVault(IERC20(depositTokenAddress), vaultName, vaultSymbol);
        NFTGifts nftGifts = new NFTGifts(address(communityVault), address(users));
        vm.stopBroadcast();

        return (soulboundBadges, users, communityVault, nftGifts, helperConfig);
    }
}
