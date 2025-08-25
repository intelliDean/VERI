//// SPDX-License-Identifier: MIT
//pragma solidity 0.8.29;
//
//import "../contracts/Ownership.sol";
//import "../contracts/EriErrors.sol";
//import {IEri} from "../contracts/IEri.sol";
//import {OwnershipLib} from "../contracts/OwnershipLib.sol";
//import {Ownership} from "../contracts/Ownership.sol";
//import {Test} from "forge-std/Test.sol";
//
//contract UserRegistration is Test {
//    Ownership public ownership;
//    address public ownershipAddress;
//
//    address public owner = address(0x123);
//    address public manufacturer = address(0x456);
//    address public firstOwner = address(0x789);
//    address public secondOwner = address(0x112);
//    address public zeroAddress = address(0);
//
//
//
//    function setUp() public {
//        // Deploy Ownership contract
//        vm.prank(owner);
//        ownership = new Ownership(owner); //owner is the one performing this transaction
//    }
//
//    // Helper: Register a user
//    function registerUser(address user, string memory username) internal {
//        vm.prank(user);
//        ownership.userRegisters(username);
//    }
//
//    // Test: Contract deployment
//    function testDeployContract() public {
//
//        ownership = new Ownership(owner);
//        ownershipAddress = address (ownership);
//
////        assertEq(ownership.owner(), owner, "Owner should be set");
//    }
//
//    // Test: userRegisters
//    function testUserRegisters() public {
//        string memory username = "Dean.eth";
//
//        vm.prank(firstOwner);
//        ownership.userRegisters(username);
//
//        IEri.UserProfile memory user = ownership.getUser(firstOwner);
//
//        assertEq(user.userAddress, firstOwner, "User address should match");
//        assertEq(user.username, username, "Username should match");
//        assertTrue(user.isRegistered, "User should be registered");
//    }
//
//    function testUsersCannotRegisterWithDuplicateUsername() public {
//        string memory username = "alice";
//        registerUser(firstOwner, username);
//
//        vm.prank(secondOwner);
//        vm.expectRevert(abi.encodeWithSelector(EriErrors.NAME_NOT_AVAILABLE.selector, username));
//        ownership.userRegisters(username);
//    }
//
//
//    function testUserCannotHaveDuplicateRegistration() public {
//        registerUser(firstOwner, "alice");
//
//        vm.prank(firstOwner);
//        vm.expectRevert(abi.encodeWithSelector(EriErrors.ALREADY_REGISTERED.selector, firstOwner));
//        ownership.userRegisters("alicia");
//    }
//
//    function testCannotRegistersWithAddressZero() public {
//        vm.prank(zeroAddress);
//        vm.expectRevert(abi.encodeWithSelector(EriErrors.ADDRESS_ZERO.selector, zeroAddress));
//        ownership.userRegisters("alice"); // Should revert
//    }
//
//    function testUsernameMustHaveAtLeast3Letters() public {
//        vm.prank(firstOwner);
//
//        vm.expectRevert(abi.encodeWithSelector(EriErrors.USERNAME_MUST_BE_AT_LEAST_3_LETTERS.selector));
//        ownership.userRegisters("me"); // Should revert
//    }
//
//    // Test: getUser
//    function testGetUser() public {
//        registerUser(firstOwner, "alice");
//
//        IEri.UserProfile memory user = ownership.getUser(firstOwner);
//        assertEq(user.username, "alice", "Username should match");
//    }
//
//    function testThatUserDoesNotExist() public {
//        vm.expectRevert(abi.encodeWithSelector(EriErrors.USER_DOES_NOT_EXIST.selector, firstOwner));
//        ownership.getUser(firstOwner); // Should revert
//    }
//}