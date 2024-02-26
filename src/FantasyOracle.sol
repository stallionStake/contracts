// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

// NOTE : can we use chainlink functions for this : https://docs.chain.link/chainlink-functions/getting-started

contract fantasyOracle {

    struct fantasyResult {
        uint256 playerId;
        uint256 timeId;
        uint256 score;
    }

    address public admin;

    constructor(address _admin) {
        admin = _admin;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    // TIME => UNIX Time stap / seconds per day
    mapping(uint256 => mapping(uint256 => uint256)) public fantasyScores;

    function getFantasyScore(uint256 _playerId, uint256 _time) public view returns (uint256) {
        // TO DO - get fantasy score from API
        return fantasyScores[_playerId][_time];
    }

    function addLatestScores(uint256[] memory _playerIds, uint256[] memory _results, uint256 time) external onlyAdmin {
        // TO DO - get latest scores from API
        uint256 _n = _results.length;

        for (uint256 i = 0; i < _n; i++) {
            _writeFantasyScore(_playerIds[i], time, _results[i]);
        }

    }


    function _writeFantasyScore(uint256 _playerId, uint256 _time, uint256 _score) internal {
        fantasyScores[_playerId][_time] = _score;
    }

    
}