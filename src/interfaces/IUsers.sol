// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IUsers {
    function getAddressFromTwitterHandle(string calldata handle_) external view returns (address);

    function getTwitterHandleFromAddress(address address_) external view returns (string memory);

    function writeTwitterHandle(address address_, string calldata twitterHandle_) external returns (bool);
}
