// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-std/console.sol";
import {Setup, ERC20, IStrategyInterface} from "./utils/Setup.sol";

import {fantasyGame} from "../FantasyGame.sol";

contract FantasyGameTest is Setup {
    function setUp() public virtual override {
        super.setUp();
    }

    function test_new_game() public {
        uint256 _amount = 1000;
        uint256 _gameStart = vm.getBlockTimestamp() + 1000;
        uint256 _nDays = 5;
        
        address _newGame = factory.createGame(address(vault), _gameStart, _nDays, _amount, false);

        console.log("address of new game", _newGame);
        assertTrue(address(0) != _newGame);

        game = fantasyGame(_newGame);

        uint256[5] memory _picks1 = [1, 2, 3, 4, 5];
        uint256[5] memory _picks2 = [6, 7, 8, 9, 10];

        airdrop(asset, user, _amount);
        airdrop(asset, user2, _amount);

        game.enterGame(_picks1, user);
        game.enterGame(_picks2, user2);

        assertEq(game.totalEntries , 2, "!totalEntries");
        assertApproxEq(game.vaultBalance, _amount * 2, _amount / 500);


    }
}
