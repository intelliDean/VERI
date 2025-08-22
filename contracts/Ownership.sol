// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "./EriErrors.sol";
import "./IEri.sol";
import "contracts/OwnershipLib.sol";
import {Authenticity} from "./Authenticity.sol";

contract Ownership {
    using OwnershipLib for *;

    address private AUTHENTICITY;

    address private immutable owner;
    // this links username to a user profile
    mapping(string => IEri.UserProfile) private users;
    //link wallet address to username
    mapping(address => string) private usernames;
    //this links itemId to the address of the owner
    mapping(string => address) private owners;
    // this links a user address to the itemId to the Item
    mapping(address => mapping(string => IEri.Item)) private ownedItems;
    //all items belonging to a user
    mapping(address => IEri.Item[]) private myItems;

    // this links the ownership code to the temp owner
    mapping(bytes32 => address) private temp;
    //this links change of ownership code to the new owner to the Item
    mapping(bytes32 => mapping(address => IEri.Item)) private tempOwners;


    event ContractCreated(address indexed contractAddress, address indexed owner);
    event UserRegistered(address indexed userAddress, string indexed username);
    event OwnershipCode(bytes32 indexed ownershipCode, address indexed tempOwner);
    event ItemCreated(string indexed itemId, address indexed owner);
    event OwnershipClaimed(address indexed newOwner, address indexed oldOwner);
    event CodeRevoked(bytes32 indexed itemHash);
    event AuthenticitySet(address indexed authenticityAddress);

    constructor(address _owner) {
        owner = _owner;

        emit ContractCreated(address(this), _owner);
    }

    modifier addressZeroCheck(address _user) {
        if (_user == address(0)) revert EriErrors.ADDRESS_ZERO(_user);
        _;
    }

    modifier onlyOwner(string memory itemId) {
        if (msg.sender != owners[itemId])
            revert EriErrors.ONLY_OWNER(msg.sender);
        _;
    }

    modifier onlyContractOwner() {
        if (msg.sender != owner)
            revert EriErrors.ONLY_OWNER(msg.sender);
        _;
    }

    modifier isAuthenticitySet() {
        if (AUTHENTICITY == address(0)) {
            revert EriErrors.AUTHENTICITY_NOT_SET();
        }
        _;
    }

    //to make sure that the createItem function can only be called by the authenticity contract,
    // we set the authenticity address here
    function setAuthenticity(address authenticityAddress) external onlyContractOwner {
        AUTHENTICITY = authenticityAddress;
        emit AuthenticitySet(authenticityAddress);
    }

    //on the frontend, when user wants to register, we check their address if they already have a basename,
    // if they have a basename, we save their basename as their username
    // if not, we suggest that they get a basename and register with a base name,
    // if not, we register them with their username
    function userRegisters(string calldata username)
    external
    addressZeroCheck(msg.sender) isAuthenticitySet {
        address userAddress = msg.sender;
        users._userRegisters(usernames, userAddress, username);
        emit UserRegistered(userAddress, username);
    }

    function getUser(address userAddress)
    public
    view isAuthenticitySet
    returns (IEri.UserProfile memory) {
        return users._getUser(usernames, userAddress);
    }

    //when a user claims item for the first time, the Originality contract call this function
    function createItem(
        address _caller,
        IEri.Certificate memory certificate,
        string memory manufacturerName
    ) external addressZeroCheck(msg.sender) addressZeroCheck(_caller) isAuthenticitySet {

        if (msg.sender != AUTHENTICITY) { //Only Authenticity contract can call this function
            revert EriErrors.UNAUTHORIZED(msg.sender);
        }

        users._createItem(
            owners,
            ownedItems,
            myItems,
            usernames,
            _caller,
            certificate,
            manufacturerName
        );

        emit ItemCreated(certificate.uniqueId, _caller);
    }

    //to get all of the items that belong to me
    function getAllMyItems()
    external
    view isAuthenticitySet
    returns (IEri.Item[] memory) {
        address user = msg.sender;
        return users._getAllItemsFor(usernames, ownedItems, myItems, user);
    }

    //========================================

    //when the owner wants to change ownership, he already knows who the new owner will be
    //so he generates a change of ownership code. he could he either give you the code or
    // you get a mail or you get an in-app notification with a link to claim ownership
    // if the new owner does not claim ownership, the owner remains the owner
    // owner can revoke change of ownership when the new owner have not claimed ownership
    //if the new owner claims ownership, old owner cannot revoke the change of ownership
    function generateChangeOfOwnershipCode(
        string memory itemId,
        address tempOwner
    )
    external
    addressZeroCheck(msg.sender) //make sure the caller is not address 0
    addressZeroCheck(tempOwner) // make sure the temp owner is not address 0
    isAuthenticitySet
    onlyOwner(itemId) {

        bytes32 itemHash = users._generateChangeOfOwnershipCode(
            usernames,
            ownedItems,
            temp,
            tempOwners,
            itemId,
            msg.sender,
            tempOwner
        );
        emit OwnershipCode(itemHash, tempOwner);
    }

    function newOwnerClaimOwnership(bytes32 itemHash)
    external
    isAuthenticitySet
    addressZeroCheck(msg.sender) {

        address newOwner = msg.sender;
        address oldOwner = users._newOwnerClaimOwnership(
            usernames,
            ownedItems,
            myItems,
            owners,
            temp,
            tempOwners,
            newOwner,
            itemHash
        );

        emit OwnershipClaimed(newOwner, oldOwner);
    }

    function getTempOwner(bytes32 itemHash) external view isAuthenticitySet returns (address)  {
        return temp[itemHash];
    }

    function ownerRevokeCode(bytes32 itemHash)
    external
    isAuthenticitySet
    addressZeroCheck(msg.sender) {
        users._ownerRevokeCode(usernames, temp, tempOwners, msg.sender, itemHash);
        emit CodeRevoked(itemHash);
    }

    //this function is meant to verify the owner of an item
    //it will return the item and all of it's information, including the owner
    function getItem(string memory itemId)
    public
    view isAuthenticitySet
    returns (IEri.Item memory) {
        return ownedItems._getItem(owners, itemId);
    }

    //when ownership is to be verified, use can either input the itemId or scan the QR code
    //if it's itemId that's input then the itemId is use
    //if it's the QR code that's signed, uniqueId is extracted from the from the certificate and use in place of itemId
    function verifyOwnership(string memory itemId)
    external
    view isAuthenticitySet
    returns (IEri.Owner memory) {
        return ownedItems._verifyOwnership(owners, usernames, itemId);
    }

    function isOwner(address user, string memory itemId)
    external
    view isAuthenticitySet
    returns (bool) {

        return ownedItems._isOwner(user, itemId);
    }

    function iOwn(string memory itemId) external view returns (bool) {

        return ownedItems._iOwn(msg.sender, itemId);
    }
}