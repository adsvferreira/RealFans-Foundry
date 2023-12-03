// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {AbstractVault} from "./AbstractVault.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CommunityVault is AbstractVault {
    constructor(IERC20 _vaultUnderlyingAsset, string memory _vaultName, string memory _symbol)
        AbstractVault(_vaultUnderlyingAsset, _vaultName, _symbol)
    {}
}
