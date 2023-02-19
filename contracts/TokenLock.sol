// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "../utils/SafeERC20.sol";

contract TokenLock {
  using SafeERC20 for IERC20;

  // ERC20 basic token contract being held
  IERC20 private _token;

  // beneficiary of tokens after they are released
  address private _beneficiary;

  // timestamp when token release is enabled
  uint256 private _releaseTime;

  // generator of the tokenLock
  address private _owner;
  bool private _ownable;

  event UnLock(address _receiver, uint256 _amount);
  event Retrieve(address _receiver, uint256 _amount);

  modifier onlyOwner() {
    require(isOwnable());
    require(msg.sender == _owner);
    _;
  }

  constructor(IERC20 token, address beneficiary, address owner, uint256 releaseTime, bool ownable) {
    _owner = owner;
    _token = token;
    _beneficiary = beneficiary;
    _releaseTime = releaseTime;
    _ownable = ownable;
  }

  /**
   * @return if this contract can be controlled by generator(owner)
   */
  function isOwnable() public view returns (bool) {
    return _ownable;
  }

  function ownerAddress() public view returns (address) {
    return _owner;
  }

  /**
   * @return the token being held.
   */
  function lockToken() public view returns (IERC20) {
    return _token;
  }

  /**
   * @return the beneficiary of the tokens.
   */
  function beneficiaryAddress() public view returns (address) {
    return _beneficiary;
  }

  /**
   * @return the time when the tokens are released.
   */
  function releaseTimeTo() public view returns (uint256) {
    return _releaseTime;
  }

  /**
   * @notice Transfers tokens held by timelock to beneficiary.
   */
  function release() public {
    require(block.timestamp >= _releaseTime);

    uint256 amount = _token.balanceOf(address(this));
    require(amount > 0);

    _token.safeTransfer(_beneficiary, amount);
    emit UnLock(_beneficiary, amount);
  }

  /**
   * @notice Retrieve tokens held by timelock to generator(owner).
   */
  function retrieve() onlyOwner public {
    uint256 amount = _token.balanceOf(address(this));
    require(amount > 0);

    _token.safeTransfer(_owner, amount);
    emit Retrieve(_owner, amount);
  }
}