// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "../contracts/Ownership.sol";
import "../contracts/EriErrors.sol";
import {IEri} from "../contracts/IEri.sol";
import {OwnershipLib} from "../contracts/OwnershipLib.sol";
import {Ownership} from "../contracts/Ownership.sol";
import {Test, Vm} from "forge-std/Test.sol";

contract ChangeOfOwnership is Test {

    Ownership public ownership;

    address public owner = address(0x123);
    address public manufacturer = address(0x456);
    address public firstOwner = address(0x789);
    address public secondOwner = address(0x112);
    address public thirdOwner = address(0x222);
    address public zeroAddress = address(0);

    // Sample certificate for item creation
    IEri.Certificate public certificate;
    string public manufacturerName = "Xiaomi";

    // Events for testing
    event ContractCreated(address indexed contractAddress, address indexed owner);
    event UserRegistered(address indexed userAddress, string indexed username);
    event ItemCreated(string indexed itemId, address indexed owner);
    event OwnershipCode(bytes32 indexed ownershipCode, address indexed tempOwner);
    event OwnershipClaimed(address indexed newOwner, address indexed oldOwner);
    event CodeRevoked(bytes32);

//    error USERNAME_NOT_AVAILABLE(string);

    function setUp() public {
        // Deploy Ownership contract
        vm.prank(owner);
        ownership = new Ownership(owner); //owner is the one performing this transaction

        // Initialize certificate
        string[] memory metadata = new string[](2);
        metadata[0] = "Xiaomi";
        metadata[1] = "5G";

        certificate = IEri.Certificate({
            name: "Redmi Note 14",
            uniqueId: "XM123456",
            serial: "SN7890",
            date: block.timestamp,
            owner: manufacturer,
            metadataHash: keccak256(abi.encode(metadata)),
            metadata: metadata
        });
    }

    // Helper: Register a user
    function registerUser(address user, string memory username) internal {
        vm.prank(user);
        ownership.userRegisters(username);
    }

    // Helper: Create an item
    function createItem(address caller, IEri.Certificate memory cert) internal {
        vm.prank(caller);
        ownership.createItem(caller, cert, manufacturerName);
    }

    // Test: Contract deployment
    function testDeployContract() public {

        ownership = new Ownership(owner);
        address expectedAddress = address (ownership);

//        assertEq(ownership.owner(), owner, "Owner should be set");
    }


    function testGenerateChangeOfOwnershipCode() public {
        //the  2 users register
        registerUser(firstOwner, "alice");
        registerUser(secondOwner, "bob");
        //first user creates an item
        createItem(firstOwner, certificate);

        vm.recordLogs();
        vm.prank(firstOwner); //first user generates a code for the second user
        ownership.generateChangeOfOwnershipCode("XM123456", secondOwner);

        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 itemHash;
        address tempOwner;

        for (uint i = 0; i < entries.length; i++) {
            if (entries[i].topics[0] == keccak256("OwnershipCode(bytes32,address)")) {
                itemHash = bytes32(entries[i].topics[1]);
                tempOwner = address(uint160(uint256(entries[i].topics[2])));
                break;
            }
        }

        assertTrue(itemHash != bytes32(0), "itemHash should not be zero");
        assertTrue(tempOwner == secondOwner, "Address mismatch");
        emit log_bytes32(itemHash); // for debugging
        emit log_address(tempOwner);
    }

    function testOnlyOwnerCanGenerateCode() public {
        registerUser(firstOwner, "alice");
        registerUser(secondOwner, "bob");
        createItem(firstOwner, certificate);

        vm.prank(secondOwner);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.ONLY_OWNER.selector, secondOwner));
        ownership.generateChangeOfOwnershipCode("XM123456", thirdOwner); // Should revert
    }

    function testCannotGenerateCodeToSelf() public {
        registerUser(firstOwner, "alice");
        createItem(firstOwner, certificate);

        vm.prank(firstOwner);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.CANNOT_GENERATE_CODE_FOR_YOURSELF.selector, firstOwner));
        ownership.generateChangeOfOwnershipCode("XM123456", firstOwner); // Should revert
    }

    function testCannotGenerateCodeForMoreThanOnePersonPerTime() public {
        registerUser(firstOwner, "alice");
        registerUser(secondOwner, "bob");
        createItem(firstOwner, certificate);


        vm.startPrank(firstOwner);
        ownership.generateChangeOfOwnershipCode("XM123456", secondOwner);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.ITEM_NOT_CLAIMED_YET.selector));
        ownership.generateChangeOfOwnershipCode("XM123456", thirdOwner); // Should revert
        vm.stopPrank();
    }


}