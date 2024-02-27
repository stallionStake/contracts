// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

// Note : Factory for creating new games 

import {fantasyGame} from "./FantasyGame.sol";

interface IGame {
    function isGameOpen() external view returns (bool);
    function isGameFinished() external view returns (bool);
}

contract fantasyFactory {

    event GameCreated(address indexed game, address indexed vault, uint256 gameStart, uint256 nDays, uint256 gameCost);

    function allGamesLength() external view returns (uint) {
        return deployedGames.length;
    }

    address[] public deployedGames;

    address public admin;
    address public oracle;

    constructor(address _admin, address _oracle) {
        admin = _admin;
        oracle = _oracle;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    function updateOracle(address _oracle) external onlyAdmin {
        oracle = _oracle;
    }

    function updateAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    function createGame(address _vault, uint256 _gameStart, uint256 _nDays, uint256 _gameCost, uint256 _maxEntries, bool _noLoss) external returns (address){
        address newGame = address(new fantasyGame(_vault, oracle, _gameStart, _nDays, _gameCost, _maxEntries, _noLoss));
        deployedGames.push(newGame);
        emit GameCreated(newGame, _vault, _gameStart, _nDays, _gameCost);
        return newGame;
    }


}