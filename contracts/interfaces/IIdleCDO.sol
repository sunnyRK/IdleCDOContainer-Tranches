// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.7;

interface IIdleCDO {
  function depositAA(uint256 _amount) external returns (uint256);
  function depositBB(uint256 _amount) external returns (uint256);
  function withdrawAA(uint256 _amount) external returns (uint256);
  function withdrawBB(uint256 _amount) external returns (uint256);
  function redeemRewards() external;
}
