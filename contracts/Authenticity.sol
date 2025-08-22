// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./EriErrors.sol";
import "./IEri.sol";

contract Authenticity is EIP712 {
    using ECDSA for bytes32;

//    string private constant SIGNING_DOMAIN = "CertificateAuth";
//    string private constant SIGNATURE_VERSION = "1";

//    bytes32 private constant CERTIFICATE_TYPE_HASH =
//    keccak256( //this will be made immutable and be the hash will be set in the constructor
//        "Certificate(string name,string uniqueId,string serial,uint256 date,address owner,bytes32 metadataHash)"
//    );

    bytes32 private immutable CERTIFICATE_TYPE_HASH;

    IEri private immutable OWNERSHIP;

    mapping(address manufacturer => IEri.Manufacturer) private manufacturers;
    mapping(string manufacturerName => address registeredAddress) private names;

    event ManufacturerRegistered(address indexed manufacturerAddress, string indexed manufacturerName);
    event ContractCreated(address indexed contractAddress, address indexed owner);

    modifier addressZeroCheck(address _user) {
        if (_user == address(0)) revert EriErrors.ADDRESS_ZERO(_user);
        _;
    }

    constructor (
        address ownershipAdd,
        string memory certificate,
        string memory signingDomain,
        string memory signatureVersion
    ) EIP712(signingDomain, signatureVersion)  {

        OWNERSHIP = IEri(ownershipAdd);

        CERTIFICATE_TYPE_HASH = keccak256(bytes(certificate));
        emit ContractCreated(address(this), msg.sender);
    }


    function manufacturerRegisters(string memory name) external addressZeroCheck(msg.sender) {

        address user = msg.sender;

        if (isRegistered(user)) {
            revert EriErrors.ALREADY_REGISTERED(user);
        }

        if (bytes(name).length < 2) {
            revert EriErrors.INVALID_MANUFACTURER_NAME(name);
        }

        if (names[name] != address(0)) {
            revert EriErrors.NAME_NOT_AVAILABLE(name);
        }

        //caller will be the owner of the contract, that's why you must call from your wallet
        IEri.Manufacturer storage newManufacturer = manufacturers[msg.sender];
        newManufacturer.manufacturerAddress = user;
        newManufacturer.name = name;

        names[name] = user;

        emit ManufacturerRegistered(user, name);
    }

    function getManufacturerByName(string calldata manufacturerName) external view returns (address)  {

        address manufacturer = names[manufacturerName];
        if (manufacturer == address(0)) {
            revert EriErrors.DOES_NOT_EXIST();
        }
        return manufacturer;
    }

    function getManufacturer(address userAddress) external view returns (IEri.Manufacturer memory) {
        if (manufacturers[userAddress].manufacturerAddress == address(0)) {
            revert EriErrors.DOES_NOT_EXIST();
        }
        return manufacturers[userAddress];
    }

    //this will be used for off-chain verification
    function getManufacturerAddress(address expectedManufacturer) public view returns (address) {

        address manufacturer = manufacturers[expectedManufacturer].manufacturerAddress;

        if (manufacturer == address(0) || expectedManufacturer != manufacturer) {
            revert EriErrors.DOES_NOT_EXIST();
        }

        return manufacturer;
    }

    function verifySignature(
        IEri.Certificate memory certificate,
        bytes memory signature
    ) public view returns (bool)  {

        // bytes32 metadataHash = keccak256(abi.encode(certificate.metadata));
        bytes32 structHash = keccak256(
            abi.encode(
                CERTIFICATE_TYPE_HASH,
                keccak256(bytes(certificate.name)),
                keccak256(bytes(certificate.uniqueId)),
                keccak256(bytes(certificate.serial)),
                certificate.date,
                certificate.owner,
                certificate.metadataHash
            )
        );

        bytes32 digest = _hashTypedDataV4(structHash);
        address signer = digest.recover(signature);

        //very important, to make sure the owner is genuine and valid
        address manufacturer = getManufacturerAddress(certificate.owner);

        //check the signer against a genuine manufacturer
        if (signer != manufacturer) {
            revert EriErrors.INVALID_SIGNATURE();
        }

        return true;
    }

    function hashTypedDataV4(bytes32 structHash) external view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }

    function userClaimOwnership(IEri.Certificate memory certificate, bytes memory signature) external addressZeroCheck(msg.sender) {
        //first check the authenticity of the signature
        bool isValid = verifySignature(certificate, signature);

        //by design, this cannot be false because instead of false, it reverts but in case
        if (!isValid) {
            revert EriErrors.INVALID_SIGNATURE();
        }

        string memory manufacturerName = manufacturers[certificate.owner].name;

        OWNERSHIP.createItem(msg.sender, certificate, manufacturerName);
    }

    function verifyAuthenticity(IEri.Certificate memory certificate, bytes memory signature) external view returns (bool, string memory) {
        //first check the authenticity of the signature
        bool isValid = verifySignature(certificate, signature);

        //by design, this cannot be false because instead of false, it reverts but in case
        if (!isValid) {
            revert EriErrors.INVALID_SIGNATURE();
        }

        string memory manufacturerName = manufacturers[certificate.owner].name;

        return (isValid, manufacturerName);
    }

    function isRegistered(address user) internal view returns (bool) {
        return manufacturers[user].manufacturerAddress != address(0);
    }
}
