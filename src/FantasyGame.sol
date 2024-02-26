// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.18;

import {IERC4626} from "@openzeppelin/contracts/interfaces/IERC4626.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IFantasyOracle} from "./interfaces/IFantasyOracle.sol";

// NOTE : can we do NFT style game ??? 

contract fantasyGame {

    // Vault that locked funds are deposited into 
    mapping(uint256 => uint256[]) public playerPicks;
    mapping(uint256 => address) public entryOwner;
    mapping(address => uint256) public nEntries;
    mapping(uint256 => uint256) public playerScores;
    mapping(address => bool) public claimed;

    uint256 public nWinners;

    uint256 public gameStart;
    // Should be in format of unix timestamp / seconds per day i.e. 1 unique number for each day
    uint256 public gameStartOracle;
    uint256 public nDays;
    uint256 public entryCost;

    uint256 public gameEnd;

    uint256 public winningScore;

    uint256 constant public SECONDSPERDAY = 86400;

    // NOTE : Would this always be the same for all games or would it be custom ? 
    uint256 public maxSalary = 50000;

    IERC4626 public vault;
    IERC20 public token;

    IFantasyOracle public oracle;

    bool public noLoss;
    bool public gameEnded;

    // TO DO - should be array of addresses (in case multipler players win?)
    address public winner;

    uint256 public totalPrizePool;
    uint256 public totalEntries;

    constructor(address _vault, address _oracle, uint256 _deadline, uint256 _nDays, uint256 _gameCost, bool _noLoss) {
        vault = IERC4626(_vault);
        oracle = IFantasyOracle(_oracle);
        gameStart = block.timestamp + _deadline;
        nDays = _nDays;
        entryCost = _gameCost;
        token = IERC20(vault.asset());
        token.approve(address(vault), type(uint256).max);
        noLoss = _noLoss;

        // NOTE : need to confirm logic for this (possibly have as seperate input for game start oracle?)
        gameStartOracle = gameStart / SECONDSPERDAY;
        gameEnd = gameStart + (nDays * SECONDSPERDAY);

    }

    function vaultBalance() public view returns (uint256) {
        return vault.convertToAssets(vault.balanceOf(address(this)));
    }

    function aum() public view returns (uint256) {
        return token.balanceOf(address(this)) + vaultBalance();
    }

    function areElementsUnique(uint256[5] memory _picks) public pure returns (bool) {
        for (uint i = 0; i < _picks.length; i++) {
            for (uint j = i + 1; j < _picks.length; j++) {
                if (_picks[i] == _picks[j]) {
                    return false;
                }
            }
        }
        return true;
    }

    function calculateSalary(uint256[5] memory _picks) public view returns(uint256) {
        uint256 _totalSalary = 0;
        for (uint256 i = 0; i < 5; i++) {
            _totalSalary += oracle.getPlayerSalary(_picks[i]);
        }

        return _totalSalary;
    }

    function enterGame(uint256[5] memory _picks) external {
        require(block.timestamp < gameStart, "Game has already started");
        require(_picks.length == 5, "Must pick 5 players");
        // Calculate salary for players picks 
        uint256 _salary = calculateSalary(_picks);
        require(_salary <= maxSalary, "Team Salary above limit");
        require(areElementsUnique(_picks), "Picks are not unique");
        // TO DO - make sure all players picked are different 

        token.transferFrom(msg.sender, address(this), entryCost);
        playerPicks[totalEntries] = _picks;
        entryOwner[totalEntries] = msg.sender;
        nEntries[msg.sender] += 1;

        // Deposit into vault when player enters
        vault.deposit(entryCost, address(this));

        if (!noLoss) {
            totalPrizePool += entryCost;
        }

        totalEntries += 1;

    }

    // Does this need to be permissioned i.e. any potential attack vectors with vault withdrawal ? 
    function endGame() external {
        require(block.timestamp > gameEnd, "Game has not ended");

        uint256 _nWinners = 0;

        vault.withdraw(vaultBalance(), address(this), address(this));

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
                for (uint256 k = 0; k < nDays; k++) {
                    score += oracle.getFantasyScore(playerPicks[i][j], gameStartOracle + k);
                }
            }

            playerScores[i] = score;
            // Case of multiple winners (same score)
            if (score == maxScore) {
                _nWinners += 1;
            }
            
            if (score > maxScore) {
                maxScore = score;
                _nWinners = 1;
            }


        }

        nWinners = _nWinners;
        winningScore = maxScore;
        gameEnded = true;

        // EMIT EVENT OF WHO WON

    }

    // TO DO - clean this up ~ bit awkward passing in entry ID 
    function claimWinnings(uint256 _entryId) external {
        require(gameEnded, "Game has not ended");
        require(msg.sender == entryOwner[_entryId], "This is not your entry");
        require(!claimed[msg.sender], "You have already claimed");
        require(playerScores[_entryId] == winningScore, "You did not win");

        uint256 _amountOut = totalPrizePool / nWinners;

        if (noLoss) {
            _amountOut += entryCost * nEntries[msg.sender];
        }        

        token.transfer(entryOwner[_entryId], _amountOut);
        claimed[msg.sender] = true;

    }

    function claimBackLoss() external {
        require(gameEnded, "Game has not ended");
        require(noLoss, "Game is not no loss");
        require(nEntries[msg.sender] > 0, "You have not entered");
        require(!claimed[msg.sender], "You have already claimed");

        uint256 nLosses = nEntries[msg.sender];

        uint256 amountOut = entryCost * nLosses;
        token.transfer(msg.sender, amountOut);

        claimed[msg.sender] = true;

    }



}