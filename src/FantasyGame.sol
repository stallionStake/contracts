// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {IERC4626} from "@openzeppelin/contracts/token/interfaces/IERC4626.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {IFantasyOracle} from "./interfaces/IFantasyOracle.sol";

contract fantasyGame {

    // Vault that locked funds are deposited into 
    mapping(uint256 => uint256[]) public playerPicks;
    mapping(uint256 => address) public entryOwner;
    mapping(address => uint256) public nEntries;

    uint256 public gameStart;
    uint256 public gameEnd;
    uint256 public entryCost;

    IERC4626 public vault;
    SafeERC20 public token;

    IFantasyOracle public oracle;

    bool public noLoss;
    bool public gameEnded;

    // TO DO - should be array of addresses (in case multipler players win?)
    address public winner;

    uint256 public totalPrizePool;
    uint256 public totalEntries;

    constructor(address _vault, uint256 _gameStart, uint256 _gameEnd, uint256 _gameCost) {
        vault = IERC4626(_vault);
        gameStart = _gameStart;
        gameEnd = _gameEnd;
        entryCost = _gameCost;
        token = SafeERC20(vault.token());
        token.approve(address(vault), type(uint256).max);

        // TO DO - set oracle address
    }

    function enterGame(uint256[] memory _picks) external {
        require(block.timestamp < gameStart, "Game has already started");
        require(_picks.length == 5, "Must pick 5 players");
        // Can player enter multiple times?

        // TO DO - check constraints i.e. player cost ??? 
        token.safeTransferFrom(msg.sender, address(this), entryCost);
        playerPicks[totalEntries] = _picks;
        entryOwner[totalEntries] = msg.sender;
        nEntries[msg.sender] += 1;

        // Deposit into vault when player enters
        vault.deposit(entryCost);

        if (!noLoss) {
            totalPrizePool += entryCost;
        }

        totalEntries += 1;

    }

    // Does this need to be permissioned i.e. any potential attack vectors with vault withdrawal ? 
    function endGame() external {
        require(block.timestamp > gameEnd, "Game has not ended");

        uint256 winningId;

        vault.withdraw(vault.balanceOf(address(this)));

        uint256 totalYield = token.balanceOf(address(this)) - (totalEntries * entryCost);

        if (noLoss) {
            totalPrizePool = totalYield;
        } else {
            totalPrizePool += totalYield;
        }

        uint256 maxScore = 0;

        for (uint256 i = 0; i < totalEntries; i++) {
            uint256 score = 0;
            for (uint256 j = 0; j < 5; j++) {
                // TO DO - get player score from oracle
                score += oracle.getFantasyScore(playerPicks[i][j], gameStart, gameEnd);
            }
            if (score > maxScore) {
                maxScore = score;
                winningId = i;
            }
        }

        winner = entryOwner[winningId];
        gameEnded = true;
        // TO DO - calculate winners
        // Loop through all picks and calculate score ??? 

        // TO DO - distribute winnings
    }


    function claimWinnings() external {
        require(gameEnded, "Game has not ended");
        require(msg.sender == winner, "You are not the winner");

        token.safeTransfer(winner, totalPrizePool);
    }

    function claimBackLoss() external {
        require(gameEnded, "Game has not ended");
        require(noLoss, "Game is not no loss");
        require(nEntries[msg.sender] > 0, "You have not entered");

        uint256 nLosses = nEntries[msg.sender] - 1;

        if (msg.sender == winner) {
            nLosses -= 1;
        }

        uint256 amountOut = entryCost * nLosses;
        token.safeTransfer(msg.sender, amountOut);


    }



}