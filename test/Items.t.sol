// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.29;

// import "../contracts/Ownership.sol";
// import "../contracts/EriErrors.sol";
// import {IEri} from "../contracts/IEri.sol";
// import {OwnershipLib} from "../contracts/OwnershipLib.sol";
// import {Ownership} from "../contracts/Ownership.sol";
// import {Test, Vm} from "forge-std/Test.sol";

// contract Items is Test {
//     Ownership public ownership;
//     address public ownershipAddress;
//     address public owner = address(0x123);
//     address public manufacturer = address(0x456);
//     address public firstOwner = address(0x789);
//     address public secondOwner = address(0x112);
//     address public thirdOwner = address(0x222);
//     address public zeroAddress = address(0);

//     // Sample certificate for item creation
//     IEri.Certificate public certificate;
//     string public manufacturerName = "Xiaomi";

//     // Events for testing
//     event ContractCreated(address indexed contractAddress, address indexed owner);
//     event UserRegistered(address indexed userAddress, string indexed username);
//     event ItemCreated(string indexed itemId, address indexed owner);
//     event OwnershipCode(bytes32 indexed ownershipCode, address indexed tempOwner);
//     event OwnershipClaimed(address indexed newOwner, address indexed oldOwner);
//     event CodeRevoked(bytes32);

// //    error USERNAME_NOT_AVAILABLE(string);

//     function setUp() public {
//         // Deploy Ownership contract
//         vm.prank(owner);
//         ownership = new Ownership(owner); //owner is the one performing this transaction

//         // Initialize certificate
//         string[] memory metadata = new string[](2);
//         metadata[0] = "Xiaomi";
//         metadata[1] = "5G";

//         certificate = IEri.Certificate({
//             name: "Redmi Note 14",
//             uniqueId: "XM123456",
//             serial: "SN7890",
//             date: block.timestamp,
//             owner: manufacturer,
//             metadata: metadata,
//             metadataHash: keccak256(abi.encode(metadata))
//         });
//     }

//     // Helper: Register a user
//     function registerUser(address user, string memory username) internal {
//         vm.prank(user);
//         ownership.userRegisters(username);
//     }

//     // Helper: Create an item
//     function createItem(address caller, IEri.Certificate memory cert) internal {
//         vm.prank(caller);
//         ownership.createItem(caller, cert, manufacturerName);
//     }

//     function generateChangeOfOwnershipCode(address firstCaller, address secondCaller) public returns(bytes32){
//         //the  2 users register
//         registerUser(firstCaller, "alice");
//         registerUser(secondCaller, "bob");
//         //first user creates an item
//         createItem(firstCaller, certificate);

//         vm.recordLogs();
//         vm.prank(firstOwner); //first user generates a code for the second user
//         ownership.generateChangeOfOwnershipCode("XM123456", secondCaller);

//         Vm.Log[] memory entries = vm.getRecordedLogs();
//         bytes32 itemHash;
//         address tempOwner;

//         for (uint i = 0; i < entries.length; i++) {
//             if (entries[i].topics[0] == keccak256("OwnershipCode(bytes32,address)")) {
//                 itemHash = bytes32(entries[i].topics[1]);
//                 tempOwner = address(uint160(uint256(entries[i].topics[2])));
//                 break;
//             }
//         }

//         assertTrue(itemHash != bytes32(0), "itemHash should not be zero");
//         assertTrue(tempOwner == secondCaller, "Address mismatch");
//         emit log_bytes32(itemHash); // for debugging
//         emit log_address(tempOwner);

//         return itemHash;
//     }

//     // Test: Contract deployment
//     function testDeployContract() public {

//         ownership = new Ownership(owner);
//         ownershipAddress = address (ownership);

// //        assertEq(ownership.owner(), owner, "Owner should be set");

//     }

//     // Test: getItem
//     function testGetItem() public {
//         registerUser(firstOwner, "alice");
//         createItem(firstOwner, certificate);

//         IEri.Item memory item = ownership.getItem("XM123456");

//         assertEq(item.itemId, "XM123456", "Item ID should match");
//         assertEq(item.owner, firstOwner, "Owner should match");
//     }

//     function testInvalidItemID() public {
//         string memory fakeItemID = "FAKE_ID";
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.ITEM_DOESNT_EXIST.selector, fakeItemID));
//         ownership.getItem(fakeItemID); // Should revert
//     }

//     // Test: verifyOwnership
//     function testVerifyOwnership() public {
//         registerUser(firstOwner, "alice");
//         createItem(firstOwner, certificate);

//         IEri.Owner memory ownerInfo = ownership.verifyOwnership("XM123456");
//         assertEq(ownerInfo.itemId, "XM123456", "Item ID should match");
//         assertEq(ownerInfo.owner, firstOwner, "Owner should match");
//         assertEq(ownerInfo.username, "alice", "Username should match");
//         assertEq(ownerInfo.name, "Redmi Note 14", "Name should match");
//     }

//     function testNonExistenceOwner() public {
//         string memory fakeItemID = "FAKE_ID";
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.ITEM_DOESNT_EXIST.selector, fakeItemID));
//         ownership.verifyOwnership(fakeItemID); // Should revert
//     }

//     // Test: isOwner
//     function testIsOwner() public {
//         registerUser(firstOwner, "alice");
//         createItem(firstOwner, certificate);

//         assertTrue(ownership.isOwner(firstOwner, "XM123456"), "User1 should be owner");
//         assertFalse(ownership.isOwner(secondOwner, "XM123456"), "User2 should not be owner");
//     }

//     function testWillBeFalse() public {
//         assertFalse(ownership.isOwner(manufacturer, "nonexistent")); // Should revert
//     }

//     // Test: iOwn
//     function testIOwn() public {
//         registerUser(firstOwner, "alice");
//         createItem(firstOwner, certificate);

//         vm.prank(firstOwner);
//         assertTrue(ownership.iOwn("XM123456"), "User1 should own item");

//         vm.prank(secondOwner);
//         assertFalse(ownership.iOwn("XM123456"), "User2 should not own item");
//     }

//     function testIDontOwnWillBeFalse() public {
//         vm.prank(firstOwner);
//         assertFalse(ownership.iOwn("nonexistent")); // Should revert
//     }
// }