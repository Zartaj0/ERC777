/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
pragma solidity ^0.8.0;

import {ERC20Token} from "./ERC20Token.sol";
import {ERC777BaseToken} from "./ERC777BaseToken.sol";

contract ERC777ERC20BaseToken is ERC20Token, ERC777BaseToken {
    bool internal mErc20compatible;

    mapping(address => mapping(address => uint256)) internal mAllowed;

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _granularity,
        address[] memory _defaultOperators
    ) ERC777BaseToken(_name, _symbol, _granularity, _defaultOperators) {
        mErc20compatible = true;
        // setInterfaceImplementation("ERC20Token", address(this));
    }

    /// @notice This modifier is applied to erc20 obsolete methods that are
    ///  implemented only to maintain backwards compatibility. When the erc20
    ///  compatibility is disabled, this methods will fail.
    modifier erc20() {
        require(mErc20compatible, "ERC20 is disabled");
        _;
    }

    function name()
        public
        view
        override(ERC777BaseToken, ERC20Token)
        returns (string memory)
    {
        return mName;
    }

    /// @return the symbol of the token
    function symbol()
        public
        view
        override(ERC777BaseToken, ERC20Token)
        returns (string memory)
    {
        return mSymbol;
    }

    /// @return the total supply of the token
    function totalSupply()
        public
        view
        override(ERC777BaseToken, ERC20Token)
        returns (uint256)
    {
        return mTotalSupply;
    }

    function balanceOf(
        address _tokenHolder
    ) public view override(ERC777BaseToken, ERC20Token) returns (uint256) {
        return mBalances[_tokenHolder];
    }

    /// @notice For Backwards compatibility
    /// @return The decimals of the token. Forced to 18 in ERC777.
    function decimals() public view erc20 returns (uint8) {
        return uint8(18);
    }

    /// @notice ERC20 backwards compatible transfer.
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return success `true`, if the transfer can't be done, it should fail.
    function transfer(
        address _to,
        uint256 _amount
    ) public erc20 returns (bool success) {
        doSend(msg.sender, msg.sender, _to, _amount, "", "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible transferFrom.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The number of tokens to be transferred
    /// @return success `true`, if the transfer can't be done, it should fail.
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public erc20 returns (bool success) {
        require(
            _amount <= mAllowed[_from][msg.sender],
            "Not enough funds allowed"
        );

        // Cannot be after doSend because of tokensReceived re-entry
        mAllowed[_from][msg.sender] = mAllowed[_from][msg.sender]-_amount;
        doSend(msg.sender, _from, _to, _amount, "", "", false);
        return true;
    }

    /// @notice ERC20 backwards compatible approve.
    ///  `msg.sender` approves `_spender` to spend `_amount` tokens on its behalf.
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The number of tokens to be approved for transfer
    function approve(
        address _spender,
        uint256 _amount
    ) public erc20 returns (bool success) {
        mAllowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @notice ERC20 backwards compatible allowance.
    ///  This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return remaining Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(
        address _owner,
        address _spender
    ) public view erc20 returns (uint256 remaining) {
        return mAllowed[_owner][_spender];
    }

    function doSend(
        address _operator,
        address _from,
        address _to,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData,
        bool _preventLocking
    ) internal override {
        super.doSend(
            _operator,
            _from,
            _to,
            _amount,
            _data,
            _operatorData,
            _preventLocking
        );
        if (mErc20compatible) {
            emit Transfer(_from, _to, _amount);
        }
    }

    function doBurn(
        address _operator,
        address _tokenHolder,
        uint256 _amount,
        bytes memory _data,
        bytes memory _operatorData
    ) internal override {
        super.doBurn(_operator, _tokenHolder, _amount, _data, _operatorData);
        if (mErc20compatible) {
            emit Transfer(_tokenHolder, address(0), _amount);
        }
    }
}
