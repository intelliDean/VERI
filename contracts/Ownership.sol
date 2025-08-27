// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "./EriErrors.sol";
import "./IEri.sol";
import {Authenticity} from "./Authenticity.sol";

contract Ownership {

    address private AUTHENTICITY;

    address private immutable owner;

    //link wallet address to username
    mapping(address => string) private usernames;

    // this links itemId to the Item
    mapping(string => IEri.Item) private items;


    event OwnershipCreated(
        address indexed contractAddress,
        address indexed owner
    );
    //todo: to remove username and leave only the userAddress, or remove username indexing so it's emitted raw
    event UserRegistered(address indexed userAddress, string username);
    event ItemCreated(string itemId);
    event OwnershipTransferred(
        string itemId,
        address indexed newOnwer,
        address indexed oldOnwer
    );
    // event CodeRevoked(bytes32 indexed itemHash);
    event AuthenticitySet(address indexed authenticityAddress);

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipCreated(address(this), _owner);
    }

    modifier addressZeroCheck(address _user) {
        if (_user == address(0)) revert EriErrors.ADDRESS_ZERO(_user);
        _;
    }

    modifier onlyContractOwner() {
        if (msg.sender != owner) revert EriErrors.ONLY_OWNER(msg.sender);
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
    function setAuthenticity(
        address authenticityAddress
    ) external onlyContractOwner {
        AUTHENTICITY = authenticityAddress;
        emit AuthenticitySet(authenticityAddress);
    }

    //on the frontend, when user wants to register, we check their address if they already have a basename,
    // if they have a basename, we save their basename as their username
    // if not, we suggest that they get a basename and register with a base name,
    // if not, we register them with their username
    function userRegisters(
        string calldata username
    ) external addressZeroCheck(msg.sender) isAuthenticitySet {

        address userAddress = msg.sender;

        if (bytes(username).length < 3) {
            revert EriErrors.USERNAME_MUST_BE_AT_LEAST_3_LETTERS();
        }

        //reverts if wallet address has already registered
        if (bytes(usernames[userAddress]).length > 2) {
            revert EriErrors.ALREADY_REGISTERED(userAddress);
        }

        usernames[userAddress] = username;

        emit UserRegistered(userAddress, username);
    }

    //this returns the username of a user instead of the whole user profile
    function getUsername(
        address userAddress
    ) public view isAuthenticitySet returns (string memory) {

        if (bytes(usernames[userAddress]).length == 0) {
            revert EriErrors.USER_DOES_NOT_EXIST(userAddress);
        }

        return usernames[userAddress];
    }

    //when a user claims item for the first time, the Originality contract call this function
    function createItem(
        address _caller,
        IEri.Certificate memory certificate,
        string memory manufacturerName
    )
    external
    addressZeroCheck(msg.sender)
    addressZeroCheck(_caller)
    isAuthenticitySet
    {
        //TODO: I REMOVED IT FOR TESTING PURPOSE, I WILL ADD IT BACK FOR PRODUCTION
        //        if (msg.sender != AUTHENTICITY) { //Only Authenticity contract can call this function
        //            revert EriErrors.UNAUTHORIZED(msg.sender);
        //        }

        if (certificate.owner == address(0)) {
            revert EriErrors.ADDRESS_ZERO(address(0));
        }

        if (!isRegistered(_caller)) {
            revert EriErrors.NOT_REGISTERED(_caller);
        }

        string memory itemId = certificate.uniqueId;

        if (items[itemId].owner != address(0)) {
            revert EriErrors.ITEM_CLAIMED_ALREADY(itemId);
        }

        IEri.Item storage item = items[itemId];

        item.itemId = itemId;
        item.owner = _caller;
        item.name = certificate.name;
        item.date = certificate.date;
        item.manufacturer = manufacturerName;
        item.metadata = certificate.metadata;
        item.serial = certificate.serial;

        emit ItemCreated(certificate.uniqueId);
    }

    // function newOwnerClaimOwnership(bytes32 itemHash)
    function newOwnerClaimOwnership(
        string memory itemId
    ) external isAuthenticitySet addressZeroCheck(msg.sender) {
        address _caller = msg.sender;
        if (!isRegistered(_caller)) {
            revert EriErrors.NOT_REGISTERED(_caller);
        }

        address newOwner = _caller;

        //item mus exist to change owner, else we'll be creating a new item
        if (items[itemId].owner == address(0)) {
            revert EriErrors.ITEM_DOESNT_EXIST(itemId);
        }

        IEri.Item storage _item = items[itemId];

        address oldOwner = _item.owner;

        _item.owner = newOwner;

        emit OwnershipTransferred(itemId, newOwner, oldOwner);
    }

    //this function is meant to verify the owner of an item
    //it will return the item and all of it's information, including the owner
    function getItem(
        string memory itemId
    ) public view isAuthenticitySet returns (IEri.Item memory) {
        if (items[itemId].owner == address(0)) {
            revert EriErrors.ITEM_DOESNT_EXIST(itemId);
        }

        return items[itemId];
    }

    //when ownership is to be verified, use can either input the itemId or scan the QR code
    //if it's itemId that's input then the itemId is use
    //if it's the QR code that's signed, uniqueId is extracted from the from the certificate and use in place of itemId
    function verifyOwnership(
        string memory itemId
    ) external view isAuthenticitySet returns (IEri.Owner memory) {
        IEri.Item memory _item = getItem(itemId);

        return
            IEri.Owner({
            name: _item.name,
            itemId: _item.itemId,
            username: usernames[_item.owner],
            owner: _item.owner
        });
    }

    function isOwner(
        address user,
        string memory itemId
    ) external view isAuthenticitySet returns (bool) {
        return items[itemId].owner == user;
    }

    function iOwn(string memory itemId) external view returns (bool) {
        return items[itemId].owner == msg.sender;
    }

    function isRegistered(
        address userAddress
    ) internal view returns (bool) {

        return bytes(usernames[userAddress]).length > 2;
    }
}
