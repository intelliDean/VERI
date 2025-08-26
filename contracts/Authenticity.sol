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

    //TODO-> TO REMOVE THIS COMPLETELY (DATABASE WILL CATER FOR THIS)
//    mapping(string manufacturerName => address registeredAddress) private names;

    //TODO: I will remove manufacturerName(on the index) from the event, leaving only manufacturerAddress
    // i added username to data instead of indexing it so that it can come out as a raw data and not hash
    event ManufacturerRegistered(address indexed manufacturerAddress, string username);
    event AuthenticityCreated(address indexed contractAddress, address indexed owner);
//    event ItemCreated(string indexed itemId, address indexed owner);

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

        emit AuthenticityCreated(address(this), msg.sender);
    }


    function manufacturerRegisters(string memory name) external addressZeroCheck(msg.sender) {

        address manufacturerToBe = msg.sender;

        if (manufacturers[manufacturerToBe].manufacturerAddress != address(0)) {
            revert EriErrors.ALREADY_REGISTERED(manufacturerToBe);
        }

        if (bytes(name).length < 2) {
            revert EriErrors.INVALID_MANUFACTURER_NAME(name);
        }

        // When manufacturer wants to register, a call will be made to the backend to check
        // the availability of the username before the transaction is sent to the smart contract
        // so this check will no longer be needed on the smart contract
        // if (names[name] != address(0)) {
        //     revert EriErrors.NAME_NOT_AVAILABLE(name);
        // }

        //caller will be the owner of the contract, that's why you must call from your wallet
        IEri.Manufacturer storage newManufacturer = manufacturers[msg.sender];
        newManufacturer.manufacturerAddress = manufacturerToBe;
        newManufacturer.name = name;

        //TODO: I will remove this
        // names[name] = user;

        emit ManufacturerRegistered(manufacturerToBe, name);
    }

    //TODO-> TO REMOVE THIS AND DO ON THE DATABASE
    // function getManufacturerByName(string calldata manufacturerName) external view returns (address)  {

    //     address manufacturer = names[manufacturerName];
    //     if (manufacturer == address(0)) {
    //         revert EriErrors.DOES_NOT_EXIST();
    //     }
    //     return manufacturer;
    // }

    //TODO-> THIS STAYS ON THE SMART CONTRACT
    function getManufacturer(address userAddress) external view returns (IEri.Manufacturer memory) {
        if (manufacturers[userAddress].manufacturerAddress == address(0)) {
            revert EriErrors.DOES_NOT_EXIST();
        }
        return manufacturers[userAddress];
    }

    //TODO-> TO REMOVE THIS AND DO ON THE DATABASE
    //this will be used for off-chain verification
    // function getManufacturerAddress(address expectedManufacturer) public view returns (address) {

    //     address manufacturer = manufacturers[expectedManufacturer].manufacturerAddress;

    //     if (manufacturer == address(0) || expectedManufacturer != manufacturer) {
    //         revert EriErrors.DOES_NOT_EXIST();
    //     }

    //     return manufacturer;
    // }

    //TODO-> THIS STAYS ON THE SMART CONTRACT
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
//        address manufacturer = getManufacturerAddress(certificate.owner);
        //===

        //very important, to make sure the owner is genuine and valid
        address manufacturerAddress = manufacturers[certificate.owner].manufacturerAddress;

        if (manufacturerAddress == address(0) || certificate.owner != manufacturerAddress) {
            revert EriErrors.DOES_NOT_EXIST();
        }

        //check the signer against a genuine manufacturer
        if (signer != manufacturerAddress) {
            revert EriErrors.INVALID_SIGNATURE();
        }

        return true;
    }

    //TODO-> THIS WILL BE REMOVED AFTER ALL (IT'S ONLY USED FOR TESTING)
   function hashTypedDataV4(bytes32 structHash) external view returns (bytes32) {
       return _hashTypedDataV4(structHash);
   }

    //TODO-> THIS STAYS ON THE SMART CONTRACT
    function userClaimOwnership(IEri.Certificate memory certificate, bytes memory signature) external addressZeroCheck(msg.sender) {
        //first check the authenticity of the signature
        bool isValid = verifySignature(certificate, signature);

        //by design, this cannot be false because instead of false, it reverts but in case
        if (!isValid) {
            revert EriErrors.INVALID_SIGNATURE();
        }

        string memory manufacturerName = manufacturers[certificate.owner].name;

        OWNERSHIP.createItem(msg.sender, certificate, manufacturerName);
//        emit ItemCreated(certificate.uniqueId, msg.sender);
    }

    //TODO-> THIS STAYS ON THE SMART CONTRACT
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
}
