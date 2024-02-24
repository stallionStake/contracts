// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;


contract fantasyOracle {

    struct fantasyResult {
        uint256 playerId;
        uint256 startTime;
        uint256 score;
    }

    address public admin;

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    mapping(uint256 => mapping(uint256 => uint256)) public fantasyScores;

    function getFantasyScore(uint256 _playerId, uint256 _time, uint256 _endTime) external view returns (uint256) {
        // TO DO - get fantasy score from API
        return 0;
    }

    function addLatestScores(fantasyResult[] memory _results) external onlyAdmin {
        // TO DO - get latest scores from API
        uint256 _n = _results.length;

        for (uint256 i = 0; i < _n; i++) {
            _writeFantasyScore(_results[i].playerId, _results[i].startTime, _results[i].score);
        }

    }


    function _writeFantasyScore(uint256 _playerId, uint256 _time, uint256 _score) internal {
        fantasyScores[_playerId][_time] = _score;
    }

    
}