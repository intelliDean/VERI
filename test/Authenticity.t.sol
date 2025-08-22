// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {Test} from "forge-std/Test.sol";
import {Authenticity} from "../contracts/Authenticity.sol";
import {IEri} from "../contracts/IEri.sol";
import {EriErrors} from "../contracts/EriErrors.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {Ownership} from "../contracts/Ownership.sol";

contract AuthenticityTest is Test {
    Authenticity public authenticity;
    Ownership public ownership;

    address public owner = address(0x100);

    address public  manufacturer = address(0x123);
    address public  user = address(0x456);
    address  public zeroAddress = address(0);

    uint256  public manufacturerPrivateKey = 0x123456789;
    address public  manufacturerWithKey = vm.addr(manufacturerPrivateKey);


    IEri.Certificate public certificate;


    function setUp() public {

        ownership = new Ownership(owner);


        authenticity = new Authenticity(
            address(ownership),
            "Certificate(string name,string uniqueId,string serial,uint256 date,address owner,bytes32 metadataHash)",
            "CertificateAuth",
            "1"
        );


        string[] memory metadata = new string[](2);
        metadata[0] = "Xiaomi";
        metadata[1] = "5G";

        certificate = IEri.Certificate({
            name: "Redmi Note 14",
            uniqueId: "XM123456",
            serial: "SN7890",
            date: block.timestamp,
            owner: manufacturerWithKey,
            metadataHash: keccak256(abi.encode(metadata)),
            metadata: metadata
        });
    }


    function registerManufacturer(address addr, string memory name) internal {
        vm.prank(addr);
        authenticity.manufacturerRegisters(name);
    }

// to generate EIP-712 signature
    function signCertificate(address signer, uint256 privateKey, IEri.Certificate memory cert) internal view returns (bytes memory) {
        bytes32 metadataHash = keccak256(abi.encode(cert.metadata));

        bytes32 structHash = keccak256(
            abi.encode(
                keccak256(
                    "Certificate(string name,string uniqueId,string serial,uint256 date,address owner,string[] metadata)"
                ),
                keccak256(bytes(cert.name)),
                keccak256(bytes(cert.uniqueId)),
                keccak256(bytes(cert.serial)),
                cert.date,
                cert.owner,
                cert.metadata
            )
        );

        bytes32 digest = authenticity.hashTypedDataV4(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);

        return abi.encodePacked(r, s, v);
    }


    function testConstructor() public {
        Ownership ownership = new Ownership(owner);
        Authenticity newAuthenticity = new Authenticity(
            address(ownership),
            "Certificate(string name,string uniqueId,string serial,uint256 date,address owner,bytes32 metadataHash)",
            "CertificateAuth",
            "1"
        );

        emit log_address(address(newAuthenticity));
        emit log_address(address(ownership));
    }

    function testManufacturerRegisters() public {
        registerManufacturer(manufacturer, "Xiaomi");

        IEri.Manufacturer memory manu = authenticity.getManufacturer(manufacturer);

        assertEq(manu.manufacturerAddress, manufacturer, "Manufacturer address should match");
        assertEq(manu.name, "Xiaomi", "Name should match");
        assertEq(authenticity.getManufacturerByName("Xiaomi"), manufacturer, "Name mapping should match");
    }

    function testCannotRegisterMoreThanOnce() public {
        registerManufacturer(manufacturer, "Xiaomi");
        vm.expectRevert(abi.encodeWithSelector(EriErrors.ALREADY_REGISTERED.selector, manufacturer));
        registerManufacturer(manufacturer, "Samsung");
    }

    function testCannotHaveDuplicatedManufacturerName() public {
        string memory name = "Xiaomi";
        registerManufacturer(manufacturer, name);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.NAME_NOT_AVAILABLE.selector, name));
        registerManufacturer(user, name);
    }

    function testManufacturerRegistersZeroAddress() public {
        vm.prank(zeroAddress);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.ADDRESS_ZERO.selector, zeroAddress));
        authenticity.manufacturerRegisters("Xiaomi");
    }

    function testManufacturerRegistersEmptyName() public {
        vm.prank(manufacturer);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.INVALID_MANUFACTURER_NAME.selector, ""));
        authenticity.manufacturerRegisters("");
    }

    function testManufacturerRegistersShortName() public {
        vm.prank(manufacturer);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.INVALID_MANUFACTURER_NAME.selector, "v"));
        authenticity.manufacturerRegisters("v");
    }

    function testGetManufacturerByName() public {
        string memory name = "Xiaomi";

        registerManufacturer(manufacturer, name);
        address addr = authenticity.getManufacturerByName(name);

        assertEq(addr, manufacturer, "Manufacturer address should match");
    }

    function testGetManufacturerByNameNonExistent() public {

        vm.expectRevert(abi.encodeWithSelector(EriErrors.DOES_NOT_EXIST.selector));
        authenticity.getManufacturerByName("NonExistent");
    }

    function testGetManufacturerAddress() public {
        registerManufacturer(manufacturer, "Xiaomi");
        address addr = authenticity.getManufacturerAddress(manufacturer);
        assertEq(addr, manufacturer, "Manufacturer address should match");
    }

    function testGetManufacturerAddressNonExistent() public {
        vm.expectRevert(abi.encodeWithSelector(EriErrors.DOES_NOT_EXIST.selector));
        authenticity.getManufacturerAddress(manufacturer);
    }

    function testGetManufacturerAddressMismatch() public {
        registerManufacturer(manufacturer, "Xiaomi");
        vm.expectRevert(abi.encodeWithSelector(EriErrors.DOES_NOT_EXIST.selector));
        authenticity.getManufacturerAddress(user);
    }

    function testVerifySignature() public {
        registerManufacturer(manufacturerWithKey, "Xiaomi");

        bytes memory signature = signCertificate(manufacturerWithKey, manufacturerPrivateKey, certificate);
        bool isValid = authenticity.verifySignature(certificate, signature);

        assertTrue(isValid, "Signature should be valid");
    }

    function testVerifySignatureInvalidSigner() public {
        registerManufacturer(manufacturerWithKey, "Xiaomi");
        bytes memory signature = signCertificate(manufacturerWithKey, manufacturerPrivateKey + 1, certificate);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.INVALID_SIGNATURE.selector));
        authenticity.verifySignature(certificate, signature);
    }

    function testVerifySignatureNonExistentManufacturer() public {
        bytes memory signature = signCertificate(manufacturerWithKey, manufacturerPrivateKey, certificate);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.DOES_NOT_EXIST.selector));
        authenticity.verifySignature(certificate, signature);
    }

    function testUserClaimOwnership() public {
        registerManufacturer(manufacturerWithKey, "Xiaomi");
        bytes memory signature = signCertificate(manufacturerWithKey, manufacturerPrivateKey, certificate);

        vm.prank(user);
        ownership.userRegisters("alice");

        vm.prank(user);
        authenticity.userClaimOwnership(certificate, signature);

        IEri.Item memory item = ownership.getItem(certificate.uniqueId);
        assertEq(item.owner, user);
        assertEq(item.itemId, certificate.uniqueId);
        assertEq(item.name, certificate.name);
    }

    function testUserClaimOwnershipInvalidSignature() public {
        registerManufacturer(manufacturerWithKey, "Xiaomi");
        bytes memory invalidSignature = signCertificate(manufacturerWithKey, manufacturerPrivateKey + 1, certificate);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.INVALID_SIGNATURE.selector));
        authenticity.userClaimOwnership(certificate, invalidSignature);
    }

    function testUserClaimOwnershipZeroAddress() public {
        registerManufacturer(manufacturerWithKey, "Xiaomi");
        bytes memory signature = signCertificate(manufacturerWithKey, manufacturerPrivateKey, certificate);

        vm.prank(zeroAddress);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.ADDRESS_ZERO.selector, zeroAddress));
        authenticity.userClaimOwnership(certificate, signature);
    }

    function testUserClaimOwnershipNonExistentManufacturer() public {
        bytes memory signature = signCertificate(manufacturerWithKey, manufacturerPrivateKey, certificate);

        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(EriErrors.DOES_NOT_EXIST.selector));
        authenticity.userClaimOwnership(certificate, signature);
    }
}

//forge test --match-path test/Authenticity.t.sol --match-test testManufacturerRegistersZeroAddress -vvv