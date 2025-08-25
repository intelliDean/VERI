
// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.29;

// import {EriErrors} from "../contracts/EriErrors.sol";
// import {IEri} from "../contracts/IEri.sol";
// import {OwnershipLib} from "../contracts/OwnershipLib.sol";
// import {Ownership} from "../contracts/Ownership.sol";
// import {Test, Vm} from "forge-std/Test.sol";

// contract OwnershipTest is Test {
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
//             metadataHash: keccak256(abi.encode(metadata)),
//             metadata: metadata
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


//     // Test: newOwnerClaimOwnership
// //    function testNewOwnerClaimOwnership() public {
// //
// //        bytes32 itemHash = generateChangeOfOwnershipCode( firstOwner, secondOwner);
// //
// //        IEri.Item memory item = ownership.getAllItemsFor(firstOwner)[0];
// //        assertEq(item.owner, firstOwner);
// //        assertEq(item.itemId, "XM123456");
// //        assertEq(ownership.getAllItemsFor(firstOwner).length, 1, "Owner should have 1 item");
// //        assertEq(ownership.getAllItemsFor(secondOwner).length, 0);
// //
// //        vm.prank(secondOwner);
// //        ownership.newOwnerClaimOwnership(itemHash);
// //
// //        IEri.Item memory item2 = ownership.getAllItemsFor(secondOwner)[0];
// //        assertEq(item2.owner, secondOwner);
// //        assertEq(item2.itemId, "XM123456");
// //
// //        IEri.Item memory claimedItem = ownership.getItem("XM123456");
// //        assertEq(claimedItem.owner, secondOwner, "New owner should be set");
// //        assertEq(claimedItem.itemId, "XM123456", "New owner should be set");
// //
// //        assertEq(ownership.getAllItemsFor(firstOwner).length, 0, "Old owner should have no items");
// //        assertEq(ownership.getAllItemsFor(secondOwner).length, 1, "New owner should have 1 item");
// //    }

//     function testCannotClaimOwnershipIfNotRegistered() public {

//         registerUser(firstOwner, "alice");
//         createItem(firstOwner, certificate);

//         vm.recordLogs();
//         vm.prank(firstOwner); //first user generates a code for the second user
//         ownership.generateChangeOfOwnershipCode("XM123456", secondOwner);

//         Vm.Log[] memory entries = vm.getRecordedLogs();
//         bytes32 itemHash;

//         for (uint i = 0; i < entries.length; i++) {
//             if (entries[i].topics[0] == keccak256("OwnershipCode(bytes32,address)")) {
//                 itemHash = bytes32(entries[i].topics[1]);
//                 break;
//             }
//         }


//         vm.prank(secondOwner);
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.NOT_REGISTERED.selector, secondOwner));
//         ownership.newOwnerClaimOwnership(itemHash); // Should revert
//     }

//     function testCannotClaimOwnershipIfNotAssignedToYou() public {
//         bytes32 itemHash = generateChangeOfOwnershipCode(firstOwner, secondOwner);

//         registerUser(thirdOwner, "mike");

//         vm.prank(thirdOwner);
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.UNAUTHORIZED.selector, thirdOwner));
//         ownership.newOwnerClaimOwnership(itemHash); // Should revert
//     }


//     // Test: ownerRevokeCode
//     function testOwnerRevokeCode() public {
//         bytes32 itemHash = generateChangeOfOwnershipCode( firstOwner, secondOwner);

//         address tempOwner = ownership.getTempOwner(itemHash);
//         assertEq(tempOwner, secondOwner);

//         vm.prank(firstOwner);
//         ownership.ownerRevokeCode(itemHash);

//         vm.prank(secondOwner);
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.UNAUTHORIZED.selector, secondOwner));
//         ownership.newOwnerClaimOwnership(itemHash);
//     }

//     function testOnlyItemOwnerCanRevokeCode() public {
//         bytes32 itemHash = generateChangeOfOwnershipCode( firstOwner, secondOwner);

//         vm.prank(secondOwner);
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.ONLY_OWNER.selector, secondOwner));
//         ownership.ownerRevokeCode(itemHash); // Should revert
//     }

//     function testGenerateCodRevokeItAndGenerateItAgain() public  {

//         bytes32 itemHash = generateChangeOfOwnershipCode( firstOwner, secondOwner);

//         address tempOwner = ownership.getTempOwner(itemHash);
//         assertEq(tempOwner, secondOwner);

//         vm.prank(firstOwner);
//         ownership.ownerRevokeCode(itemHash);

//         vm.prank(secondOwner);
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.UNAUTHORIZED.selector, secondOwner));
//         ownership.newOwnerClaimOwnership(itemHash);


//         //=========
//         itemHash = miniGenerate(firstOwner, thirdOwner);
// //        //===================
//         tempOwner = ownership.getTempOwner(itemHash);
//         assertEq(tempOwner, thirdOwner);

//         registerUser(thirdOwner, "Mike");

//         vm.prank(thirdOwner);
//         ownership.newOwnerClaimOwnership(itemHash);
// //
//         IEri.Item memory claimedItem = ownership.getItem("XM123456");
//         assertEq(claimedItem.owner, thirdOwner);
//         assertEq(claimedItem.itemId, "XM123456");

//         vm.expectRevert(abi.encodeWithSelector(EriErrors.ONLY_OWNER.selector, firstOwner));
//         itemHash = miniGenerate( firstOwner, secondOwner);

//         itemHash = miniGenerate( thirdOwner, firstOwner);

//         vm.prank(firstOwner);
//         ownership.newOwnerClaimOwnership(itemHash);

// //        IEri.Item memory item2 = ownership.getAllItemsFor(firstOwner)[0];
// //        assertEq(item2.owner, firstOwner);
// //        assertEq(item2.itemId, "XM123456");
//     }

//     function miniGenerate(address owner, address newOwner) public  returns (bytes32 itemHash)  {
//         vm.recordLogs();
//         vm.prank(owner); //first user generates a code for the second user
//         ownership.generateChangeOfOwnershipCode("XM123456", newOwner);

//         Vm.Log[] memory entries = vm.getRecordedLogs();

//         for (uint i = 0; i < entries.length; i++) {
//             if (entries[i].topics[0] == keccak256("OwnershipCode(bytes32,address)")) {
//                 itemHash = bytes32(entries[i].topics[1]);
//                 break;
//             }
//         }

//         return itemHash;
//     }
// }