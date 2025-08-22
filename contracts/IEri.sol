// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;


interface IEri {

    struct UserProfile { // I will create a different smart contract to manage the user profile
        address userAddress;
        string username;
        bool isRegistered;
        uint256 registeredAt;
    }

    struct Manufacturer {
        string name;
        address manufacturerAddress;
    }

    struct Certificate {
        string name;
        string uniqueId;
        string serial;
        uint256 date;
        address owner;
        bytes32 metadataHash;
        string[] metadata;
    }

    struct Item {
        string name;
        string itemId; // something very unique like the IMEI of a phone
        string serial;
        uint256 date;
        address owner;
        string manufacturer;
        string[] metadata;
    }

    struct Owner {
        string name;
        string itemId; // something very unique like the IMEI of a phone
        string username;
        address owner;
    }

    function createItem(address _caller, IEri.Certificate memory certificate, string memory manufacturerName) external;
}