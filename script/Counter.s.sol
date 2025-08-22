// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import {Script, console} from "forge-std/Script.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
    }
}


//CREATE TABLE IF NOT EXISTS manufacturers (
//    id SERIAL PRIMARY KEY,
//manufacturer_address VARCHAR NOT NULL,
//manufacturer_name VARCHAR NOT NULL,
//timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
//tnx_hash TEXT NOT NULL
//);
//
//CREATE TABLE IF NOT EXISTS contracts_created (
//id SERIAL PRIMARY KEY,
//contract_address VARCHAR NOT NULL,
//owner VARCHAR NOT NULL,
//timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
//);


//DROP TABLE IF EXISTS transfers;
//DROP TABLE IF EXISTS assets;
