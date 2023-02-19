// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../erc20/ERC20.sol";
import "../access/Ownable.sol";
import "../security/Pausable.sol";
import './TokenLock.sol';

/**
 * @dev Extension of {ERC20} that adds a cap to the supply of tokens.
 */
abstract contract ERC20Capped is ERC20 {
    uint256 private immutable _cap;

    /**
     * @dev Sets the value of the `cap`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint256 cap_) {
        require(cap_ > 0, "ERC20Capped: cap is 0");
        _cap = cap_;
    }

    /**
     * @dev Returns the cap on the token's total supply.
     */
    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    /**
     * @dev See {ERC20-_mint}.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        require(ERC20.totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        super._mint(account, amount);
    }
}

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

/**
 * @dev PenSolution Token
 */
contract PenSolToken is ERC20Capped, ERC20Burnable, ERC20Pausable, Ownable {

    // Lock event
    mapping (address => address) public lockStatus;
    event Lock(address _receiver, uint256 _amount);

    // airdrop event
    mapping (address => uint256) public airDropHistory;
    event AirDrop(address _receiver, uint256 _amount);

    constructor(string memory name, string memory symbol)
        ERC20(name, symbol)
        ERC20Capped(1000000000 * (10 ** uint256(decimals())))
        Ownable() {}

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    function mintNoDcmls(address account, uint256 amount) public onlyOwner {
        _mint(account, amount * (10 ** uint256(decimals())));
    }

    function _mint(address account, uint256 amount) internal virtual override(ERC20,ERC20Capped) {
        super._mint(account, amount);
    }

    function _beforeTokenTransfer(
            address from,
            address to,
            uint256 tokenId
    ) internal virtual override (ERC20, ERC20Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);

        // do stuff before every transfer
        // e.g. check that vote (other than when minted) 
        // being transferred to registered candidate
    }

    function pause() public onlyOwner{
        super._pause();
    }

    function unpause() public onlyOwner{
        super._unpause();
    }

    function dropToken(address[] memory receivers, uint256[] memory values) public {
        require(receivers.length != 0);
        require(receivers.length == values.length);

        for (uint256 i = 0; i < receivers.length; i++) {
            address receiver = receivers[i];
            uint256 amount = values[i];

            transfer(receiver, amount);
            airDropHistory[receiver] += amount;

            emit AirDrop(receiver, amount);
        }
    }

    function lockToken(address beneficiary, uint256 amount, uint256 releaseTime, bool isOwnable) onlyOwner public {
        TokenLock lockContract = new TokenLock(this, beneficiary, msg.sender, releaseTime, isOwnable);

        transfer(address(lockContract), amount);
        lockStatus[beneficiary] = address(lockContract);
        emit Lock(beneficiary, amount);
    }
}
