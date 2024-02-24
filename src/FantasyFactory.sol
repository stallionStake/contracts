// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

// Note : Factory for creating new games 

import {fantasyGame} from "./FantasyGame.sol";

contract fantasyFactory {

    address[] public deployedGames;

    function createGame(address _vault, uint256 _gameStart, uint256 _gameEnd, uint256 _gameCost) external {
        address newGame = address(new fantasyGame(_vault, _gameStart, _gameEnd, _gameCost));
        deployedGames.push(newGame);
    }


}