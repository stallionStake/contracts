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
        // need to pass in correct time stamp data ? 
        uint256 _gameStart = 1000;
        uint256 _nDays = 5;
        uint256 balBefore;
        uint256 maxEntries = 100;
        // Test no loss version
        address _newGame = factory.createGame(address(vault), _gameStart, _nDays, _amount, maxEntries, false);

        console.log("address of new game", _newGame);
        assertTrue(address(0) != _newGame);

        game = fantasyGame(_newGame);

        uint256[5] memory _picks1 = [1, 2, 3, 4, uint256(5)];
        uint256[5] memory _picks2 = [6, 7, 8, 9, uint256(10)];

        airdrop(asset, user, _amount);
        airdrop(asset, user2, _amount);

        vm.prank(user);
        asset.approve(address(game), _amount);

        vm.prank(user);
        game.enterGame(_picks1);

        vm.prank(user2);
        asset.approve(address(game), _amount);

        vm.prank(user2);
        game.enterGame(_picks2);

        assertEq(game.totalEntries() , 2, "!totalEntries");
        assertApproxEq(game.vaultBalance(), _amount * 2, _amount / 500);

        // TIME is unique for each day (i..e block.timestamp / seconds per day)
        uint256 time = game.gameStartOracle();

        uint256[] memory _ids = new uint256[](3);
        _ids[0] = 1; // First player's id
        _ids[1] = 2; // Second player's id
        _ids[2] = 3; // Third player's id

        uint256[] memory _scores = new uint256[](3);
        _scores[0] = 123; // First player's score
        _scores[1] = 456; // Second player's score
        _scores[2] = 789; // Third player's score        

        vm.prank(management);
        oracle.addLatestScores(_ids, _scores, time);

        skip(10 days);

        vm.prank(management);
        game.endGame();

        // Check Winning Score belonds to 0th entry 
        console.log(game.winningScore(), " - Winning Score" );

        console.log(game.playerScores(0), " - Player 0 Score");
        console.log(game.playerScores(1), " - Player 1 Score");


        console.log(game.totalPrizePool(), " - Prize Pool");
        console.log(game.nWinners(), " - number of Winners");

        assertEq(game.playerScores(0), game.winningScore(), "!winner");

        balBefore = asset.balanceOf(user);


        vm.prank(user);
        game.claimWinnings(0);
        console.log("Winner Balance ", asset.balanceOf(user));
        assertGe(asset.balanceOf(user), balBefore + _amount*2, "!winning Balance");

    }




    function test_no_loss_game() public {
        uint256 _amount = 1000;
        // need to pass in correct time stamp data ? 
        uint256 _gameStart = 1000;
        uint256 _nDays = 5;
        uint256 balBefore;
        // Test no loss version
        uint256 maxEntries = 100;
        // Test no loss version
        address _newGame = factory.createGame(address(vault), _gameStart, _nDays, _amount, maxEntries, true);

        console.log("address of new game", _newGame);
        assertTrue(address(0) != _newGame);

        game = fantasyGame(_newGame);

        uint256[5] memory _picks1 = [1, 2, 3, 4, uint256(5)];
        uint256[5] memory _picks2 = [6, 7, 8, 9, uint256(10)];

        airdrop(asset, user, _amount);
        airdrop(asset, user2, _amount);

        vm.prank(user);
        asset.approve(address(game), _amount);

        vm.prank(user);
        game.enterGame(_picks1);

        vm.prank(user2);
        asset.approve(address(game), _amount);

        vm.prank(user2);
        game.enterGame(_picks2);

        assertEq(game.totalEntries() , 2, "!totalEntries");
        assertApproxEq(game.vaultBalance(), _amount * 2, _amount / 500);

        // Airdrop some assets to strategy simulate yield generated 
        airdrop(asset, address(strategy), _amount / 10);
        // Report profit
        vm.prank(keeper);
        (uint256 profit, uint256 loss) = strategy.report();

        // TIME is unique for each day (i..e block.timestamp / seconds per day)
        uint256 time = game.gameStartOracle();

        uint256[] memory _ids = new uint256[](3);
        _ids[0] = 1; // First player's id
        _ids[1] = 2; // Second player's id
        _ids[2] = 3; // Third player's id

        uint256[] memory _scores = new uint256[](3);
        _scores[0] = 123; // First player's score
        _scores[1] = 456; // Second player's score
        _scores[2] = 789; // Third player's score        

        vm.prank(management);
        oracle.addLatestScores(_ids, _scores, time);

        skip(10 days);

        // Check yield was generated 

        console.log(game.aum(), " - AUM at end of game");

        vm.prank(management);
        game.endGame();

        // Check Winning Score belonds to 0th entry 
        console.log(game.winningScore(), " - Winning Score" );

        console.log(game.playerScores(0), " - Player 0 Score");
        console.log(game.playerScores(1), " - Player 1 Score");


        console.log(game.totalPrizePool(), " - Prize Pool");
        console.log(game.nWinners(), " - number of Winners");

        assertEq(game.playerScores(0), game.winningScore(), "!winner");

        balBefore = asset.balanceOf(user);
        vm.prank(user);
        game.claimWinnings(0);
        console.log("Winner Balance ", asset.balanceOf(user));
        assertEq(asset.balanceOf(user) - balBefore, game.totalPrizePool() + _amount, "Incorrect Amount Out - Winner");

        balBefore = asset.balanceOf(user2);
        vm.prank(user2);
        game.claimBackLoss(1);
        assertEq(asset.balanceOf(user2) - balBefore,  _amount, "Incorrect Amount Out - Loser");

    }



    function test_no_loss_game_w_transfers() public {
        uint256 _amount = 1000;
        // need to pass in correct time stamp data ? 
        uint256 _gameStart = 1000;
        uint256 _nDays = 5;
        uint256 balBefore;
        // Test no loss version
        uint256 maxEntries = 100;
        // Test no loss version
        address _newGame = factory.createGame(address(vault), _gameStart, _nDays, _amount, maxEntries, true);

        console.log("address of new game", _newGame);
        assertTrue(address(0) != _newGame);

        game = fantasyGame(_newGame);

        uint256[5] memory _picks1 = [1, 2, 3, 4, uint256(5)];
        uint256[5] memory _picks2 = [6, 7, 8, 9, uint256(10)];

        airdrop(asset, user, _amount);
        airdrop(asset, user2, _amount);

        vm.prank(user);
        asset.approve(address(game), _amount);

        vm.prank(user);
        game.enterGame(_picks1);

        vm.prank(user2);
        asset.approve(address(game), _amount);

        vm.prank(user2);
        game.enterGame(_picks2);

        assertEq(game.totalEntries() , 2, "!totalEntries");
        assertApproxEq(game.vaultBalance(), _amount * 2, _amount / 500);

        // Airdrop some assets to strategy simulate yield generated 
        airdrop(asset, address(strategy), _amount / 10);
        // Report profit
        vm.prank(keeper);
        (uint256 profit, uint256 loss) = strategy.report();

        // TIME is unique for each day (i..e block.timestamp / seconds per day)
        uint256 time = game.gameStartOracle();

        uint256[] memory _ids = new uint256[](3);
        _ids[0] = 1; // First player's id
        _ids[1] = 2; // Second player's id
        _ids[2] = 3; // Third player's id

        uint256[] memory _scores = new uint256[](3);
        _scores[0] = 123; // First player's score
        _scores[1] = 456; // Second player's score
        _scores[2] = 789; // Third player's score        

        vm.prank(management);
        oracle.addLatestScores(_ids, _scores, time);

        skip(10 days);

        // Check yield was generated 

        console.log(game.aum(), " - AUM at end of game");

        vm.prank(management);
        game.endGame();

        // Check Winning Score belonds to 0th entry 
        console.log(game.winningScore(), " - Winning Score" );

        console.log(game.playerScores(0), " - Player 0 Score");
        console.log(game.playerScores(1), " - Player 1 Score");


        console.log(game.totalPrizePool(), " - Prize Pool");
        console.log(game.nWinners(), " - number of Winners");

        assertEq(game.playerScores(0), game.winningScore(), "!winner");

        // Transfer NFT's 
        vm.prank(user);
        game.transferFrom(user, user3, 0);

        vm.prank(user2);
        game.transferFrom(user2, user4, 1);

        // Check user can't claim winnings for NFT they no longer own 
        vm.prank(user);
        vm.expectRevert();
        game.claimWinnings(0);

        balBefore = asset.balanceOf(user3);
        vm.prank(user3);
        game.claimWinnings(0);
        console.log("Winner Balance ", asset.balanceOf(user3));
        assertEq(asset.balanceOf(user3) - balBefore, game.totalPrizePool() + _amount, "Incorrect Amount Out - Winner");

        // Check user can't claim loss for NFT they no longer own 
        vm.prank(user2);
        vm.expectRevert();
        game.claimBackLoss(1);

        balBefore = asset.balanceOf(user4);
        vm.prank(user4);
        game.claimBackLoss(1);
        assertEq(asset.balanceOf(user4) - balBefore,  _amount, "Incorrect Amount Out - Loser");

    }


}
