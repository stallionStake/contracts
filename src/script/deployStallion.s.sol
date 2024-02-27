// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Strategy} from "../Strategy.sol";
import {fantasyOracle} from "../FantasyOracle.sol";
import {fantasyFactory} from "../FantasyFactory.sol";

import {Script, console} from "forge-std/Script.sol";

contract DeployStallion is Script {
    address public admin;
    address public asset = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;

    function deployFantasyOracle() internal returns (address) {
        fantasyOracle oracle = new fantasyOracle(admin);
        console.log("Deployed Fantasy Oracle at ", address(oracle));
        return address(oracle);
    }

    function deployFantasyFactory(address _oracle) internal returns (address) {
        fantasyFactory factory = new fantasyFactory(admin, _oracle);
        console.log("Deployed Fantasy Factory at ", address(factory));
        return address(factory);
    }

    /*
    function deployStrategy() internal returns (address) {
        address strategy = new Strategy(address(asset), "Tokenized Strategy");
        console.log("Deployed Strategy at ", strategy);
        return strategy;
    }
    */

    function run() external {
        admin = msg.sender;
        address oracle = deployFantasyOracle();
        address factory = deployFantasyFactory(oracle);
        //deployStrategy();

        // Can also set up a game here ??? 

        // Do we want to transfer admin to some new EOA so can interact via explorer 

    }


}