// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;


interface IFantasyOracle {
    function getFantasyScore(uint256 _playerId, uint256 _timeId) external view returns (uint256);
}