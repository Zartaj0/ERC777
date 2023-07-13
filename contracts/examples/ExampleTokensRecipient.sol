/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/.
 *
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
pragma solidity ^0.8.0;

import { ERC1820Client } from "../ERC1820Client.sol";
import  "@openzeppelin/contracts/access/Ownable.sol";
import { ERC777TokensRecipient } from "../ERC777TokensRecipient.sol";
import { ERC777Token } from "../ERC777Token.sol";

interface ERC1820ImplementerInterface {

    /// @notice Indicates whether the contract implements the interface `interfaceHash` for the address `addr`.
    /// @param interfaceHash keccak256 hash of the name of the interface
    /// @param addr Address for which the contract will implement the interface
    /// @return ERC1820_ACCEPT_MAGIC only if the contract implements `ìnterfaceHash` for the address `addr`.
    function canImplementInterfaceForAddress(bytes32 interfaceHash, address addr) external view returns(bytes32);
}
contract ExampleTokensRecipient is ERC1820Client, ERC1820ImplementerInterface, ERC777TokensRecipient, Ownable {
    bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

    bool private allowTokensReceived;

    mapping(address => address) public token;
    mapping(address => address) public operator;
    mapping(address => address) public from;
    mapping(address => address) public to;
    mapping(address => uint256) public amount;
    mapping(address => bytes) public data;
    mapping(address => bytes) public operatorData;
    mapping(address => uint256) public balanceOf;

    constructor(bool _setInterface)  {
        if (_setInterface) { setInterfaceImplementation("ERC777TokensRecipient", address(this)); }
        allowTokensReceived = true;
    }

    function tokensReceived(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
    {
        require(allowTokensReceived, "Receive not allowed");
        token[_to] = msg.sender;
        operator[_to] = _operator;
        from[_to] = _from;
        to[_to] = _to;
        amount[_to] = _amount;
        data[_to] = _data;
        operatorData[_to] = _operatorData;
        balanceOf[_from] = ERC777Token(msg.sender).balanceOf(_from);
        balanceOf[_to] = ERC777Token(msg.sender).balanceOf(_to);
    }

    function acceptTokens() public onlyOwner { allowTokensReceived = true; }

    function rejectTokens() public onlyOwner { allowTokensReceived = false; }

    // solhint-disable-next-line no-unused-vars
    function canImplementInterfaceForAddress(bytes32 _interfaceHash, address _addr) external view returns(bytes32) {
        return ERC1820_ACCEPT_MAGIC;
    }
}
