// // SPDX-License-Identifier: MIT
// pragma solidity 0.8.29;

// import "../contracts/Ownership.sol";
// import "../contracts/EriErrors.sol";
// import {IEri} from "../contracts/IEri.sol";
// import {OwnershipLib} from "../contracts/OwnershipLib.txt";
// import {Ownership} from "../contracts/Ownership.sol";
// import {Test} from "forge-std/Test.sol";

// contract CreateItem is Test {
//     Ownership public ownership;
//     address public ownershipAddress;

//     IEri.Certificate public certificate;
//     string public manufacturerName = "Xiaomi";


//     address public owner = address(0x123);
//     address public manufacturer = address(0x456);
//     address public firstOwner = address(0x789);
//     address public secondOwner = address(0x112);
//     address public zeroAddress = address(0);




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

//     // Test: Contract deployment
//     function testDeployContract() public {

//         ownership = new Ownership(owner);
//         ownershipAddress = address (ownership);

// //        assertEq(ownership.owner(), owner, "Owner should be set");
//     }


//     // Test: createItem
//     function testCreateItem() public {
//         registerUser(firstOwner, "alice");
//         createItem(firstOwner, certificate);

//         IEri.Item memory item = ownership.getItem("XM123456");

//         assertEq(item.itemId, "XM123456", "Item ID should match");
//         assertEq(item.owner, firstOwner, "Owner should match");
//         assertEq(item.name, "Redmi Note 14", "Name should match");
//         assertEq(item.serial, "SN7890", "Serial should match");
//         assertEq(item.manufacturer, "Xiaomi", "Manufacturer should match");
//         assertEq(item.metadata.length, 2, "Metadata length should match");
//     }

//     function testYouCannotCreateItemIfNotRegistered() public {
//         vm.prank(firstOwner);
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.NOT_REGISTERED.selector, firstOwner));
//         ownership.createItem(firstOwner, certificate, manufacturerName); // Should revert
//     }

//     function testCannotHaveItemsWithSameItemID() public {
//         registerUser(firstOwner, "alice");
//         createItem(firstOwner, certificate);
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.ITEM_CLAIMED_ALREADY.selector, "XM123456"));
//         createItem(firstOwner, certificate); // Should revert
//     }

//     function testAddressZeroCannotBeTheCaller() public {
//         registerUser(firstOwner, "alice");
//         vm.prank(zeroAddress);
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.ADDRESS_ZERO.selector, zeroAddress));
//         ownership.createItem(firstOwner, certificate, manufacturerName); // Should revert
//     }

//     function testCertificateOwnerCannotBeAddressZero() public {
//         registerUser(firstOwner, "alice");
//         IEri.Certificate memory invalidCert = certificate;
//         invalidCert.owner = zeroAddress;
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.ADDRESS_ZERO.selector, zeroAddress));
//         createItem(firstOwner, invalidCert); // Should revert
//     }

//     function testGetAllItemsFor() public {
//         registerUser(firstOwner, "alice");
//         createItem(firstOwner, certificate);

//         IEri.Certificate memory cert2 = certificate;
//         cert2.uniqueId = "XM789012";
//         createItem(firstOwner, cert2);

//         vm.prank(firstOwner);
// //        IEri.Item[] memory items = ownership.getAllItemsFor(firstOwner);
// //
// //        assertEq(items.length, 2, "Should return 2 items");
// //        assertEq(items[1].itemId, "XM123456", "First item ID should match");
// //        assertEq(items[0].itemId, "XM789012", "Second item ID should match");
//     }

//     function testGetEmptyItemForNoItem() public {
//         registerUser(firstOwner, "alice");

//         vm.prank(firstOwner);
//         IEri.Item[] memory items = ownership.getAllMyItems(); //(firstOwner);
//         assertEq(items.length, 0, "Should return empty array");
//     }

//     function testNoRegistrationNoItem() public {
//         vm.expectRevert(abi.encodeWithSelector(EriErrors.USER_DOES_NOT_EXIST.selector, firstOwner));
//         ownership.getAllMyItems(); //(firstOwner); // Should revert
//     }
// }