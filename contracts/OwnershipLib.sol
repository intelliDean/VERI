// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;

import "./EriErrors.sol";
import "./IEri.sol";

library OwnershipLib {
    function _userRegisters(
        mapping(string => IEri.UserProfile) storage users,
        mapping(address => string) storage usernames,
        address userAddress,
        string memory username
    ) external {
        if (bytes(username).length < 3) {
            revert EriErrors.USERNAME_MUST_BE_AT_LEAST_3_LETTERS();
        }
        //reverts if username is already used by someone else
        if (isRegistered(users, username)) {
            //no duplicate username and address
            revert EriErrors.NAME_NOT_AVAILABLE(username);
        }
        //reverts if wallet address has already registered
        if (isNotEmpty(usernames[userAddress])) {
            revert EriErrors.ALREADY_REGISTERED(userAddress);
        }

        IEri.UserProfile storage _user = users[username];
        _user.userAddress = userAddress;
        _user.username = username;
        _user.isRegistered = true;
        _user.registeredAt = block.timestamp;

        //save a username with a user address, mostly for when using connect wallet
        usernames[userAddress] = username;
    }

    function _getUser(
        mapping(string => IEri.UserProfile) storage users,
        mapping(address => string) storage usernames,
        address userAddress
    ) public view returns (IEri.UserProfile memory) {
        if (users[usernames[userAddress]].userAddress == address(0)) {
            revert EriErrors.USER_DOES_NOT_EXIST(userAddress);
        }

        return users[usernames[userAddress]];
    }

    function _createItem(
        mapping(string => IEri.UserProfile) storage users,
        mapping(string => address) storage owners,
        mapping(address => mapping(string => IEri.Item)) storage ownedItems,
        mapping(address => IEri.Item[]) storage myItems,
        mapping(address => string) storage usernames,
        address _caller,
        IEri.Certificate memory certificate,
        string memory manufacturerName
    ) external {
        if (!isRegistered(users, usernames[_caller])) {
            revert EriErrors.NOT_REGISTERED(_caller);
        }

        if (certificate.owner == address(0)) {
            revert EriErrors.ADDRESS_ZERO(address(0));
        }

        string memory itemId = certificate.uniqueId;

        if (owners[itemId] != address(0)) {
            revert EriErrors.ITEM_CLAIMED_ALREADY(itemId);
        }

        IEri.Item storage item = ownedItems[_caller][itemId];

        item.itemId = itemId;
        item.owner = _caller;
        item.name = certificate.name;
        item.date = certificate.date;
        item.manufacturer = manufacturerName;
        item.metadata = certificate.metadata;
        item.serial = certificate.serial;

        owners[item.itemId] = item.owner;

        //all the items that belong to a particular user
        IEri.Item[] storage itemList = myItems[_caller];
        itemList.push(item);
    }

    //for privacy purpose, we want to make sure only the owner
    // of the items can fetch all his items, not everybody
    function _getAllItemsFor(
        mapping(string => IEri.UserProfile) storage users,
        mapping(address => string) storage usernames,
        mapping(address => mapping(string => IEri.Item)) storage ownedItems,
        mapping(address => IEri.Item[]) storage myItems,
        address user
    ) external view returns (IEri.Item[] memory) {
        if (users[usernames[user]].userAddress == address(0)) {
            revert EriErrors.USER_DOES_NOT_EXIST(user);
        }

        IEri.Item[] memory itemList = myItems[user];

        // Count valid items
        uint256 validCount = 0;
        for (uint256 i = 0; i < itemList.length; i++) {
            if (ownedItems[user][itemList[i].itemId].owner != address(0)) {
                validCount++;
            }
        }

        if (validCount == 0) {
            return new IEri.Item[](0);
        }

        // Allocate and populate array
        IEri.Item[] memory newItemList = new IEri.Item[](validCount);
        for (uint256 i = 0; i < itemList.length; i++) {
            if (ownedItems[user][itemList[i].itemId].owner != address(0)) {
                newItemList[validCount - 1] = ownedItems[user][
                    itemList[i].itemId
                ];
                validCount--;
            }
        }

        return newItemList;
    }

    function _generateChangeOfOwnershipCode(
        mapping(string => IEri.UserProfile) storage users,
        mapping(address => string) storage usernames,
        mapping(address => mapping(string => IEri.Item)) storage ownedItems,
        mapping(bytes32 => address) storage temp,
        mapping(bytes32 => mapping(address => IEri.Item)) storage tempOwners,
        string memory itemId,
        address caller,
        address tempOwner
    ) external returns (bytes32) {
        if (tempOwner == caller) {
            revert EriErrors.CANNOT_GENERATE_CODE_FOR_YOURSELF(caller);
        }
        // make sure only the item owner can generate code for the item

        if (!isRegistered(users, usernames[caller])) {
            revert EriErrors.NOT_REGISTERED(caller);
        }

        IEri.Item memory _item = ownedItems[caller][itemId];

        //this is the code the owner will give to the new owner to claim ownership
        bytes32 itemHash = keccak256(abi.encode(_item)); //it will always be the same every time

        //you cannot generate code for an item for more than 1 person at a time
        if (temp[itemHash] != address(0)) {
            revert EriErrors.ITEM_NOT_CLAIMED_YET();
        }

        // if you have already generated the code, you don't need to generate anymore (no need anymore)
        //        if (tempOwners[itemHash][tempOwner].owner != address(0)) {
        //            revert EriErrors.CODE_ALREADY_GENERATED();
        //        }

        tempOwners[itemHash][tempOwner] = _item;
        temp[itemHash] = tempOwner;

        return itemHash;
    }

    function _newOwnerClaimOwnership(
        mapping(string => IEri.UserProfile) storage users,
        mapping(address => string) storage usernames,
        mapping(address => mapping(string => IEri.Item)) storage ownedItems,
        mapping(address => IEri.Item[]) storage myItems,
        mapping(string => address) storage owners,
        mapping(bytes32 => address) storage temp,
        mapping(bytes32 => mapping(address => IEri.Item)) storage tempOwners,
        address _caller,
        bytes32 itemHash
    ) external returns (address) {
        if (!isRegistered(users, usernames[_caller])) {
            revert EriErrors.NOT_REGISTERED(_caller);
        }

        address newOwner = _caller;
        address tempOwner = temp[itemHash];

        IEri.Item memory _item = tempOwners[itemHash][newOwner];

        address oldOwner = _item.owner;

        if (tempOwner != newOwner || oldOwner == address(0)) {
            //that means msg.sender was not authorized to claim the item or itemHash is revoked
            revert EriErrors.UNAUTHORIZED(newOwner);
        }
        string memory id = _item.itemId;

        _item.owner = newOwner;

        delete ownedItems[oldOwner][id]; //delete the item from the old owner mapping

        ownedItems[newOwner][id] = _item; //save the item with the new owner key
        owners[id] = newOwner;

        IEri.Item[] storage itemList = myItems[newOwner];
        if (itemList.length == 0) {
            itemList.push(_item); //saving this item as part of my items
        } else {
            bool isPart = false;
            for (uint256 i = 0; i < itemList.length; i++) {
                if (
                    keccak256(abi.encode(itemList[i].itemId)) ==
                    keccak256(abi.encode(_item.itemId))
                ) {
                    isPart = true;
                    break;
                }
            }
            if (!isPart) {
                itemList.push(_item);
            }
        }

        delete tempOwners[itemHash][newOwner]; //delete the item from the ownership code
        delete temp[itemHash]; // the ownershipHash no longer point to the temp owner

        return oldOwner;
    }

    function _ownerRevokeCode(
        mapping(string => IEri.UserProfile) storage users,
        mapping(address => string) storage usernames,
        mapping(bytes32 => address) storage temp,
        mapping(bytes32 => mapping(address => IEri.Item)) storage tempOwners,
        address _caller,
        bytes32 itemHash
    ) external returns (bytes32) {
        if (!isRegistered(users, usernames[_caller])) {
            revert EriErrors.NOT_REGISTERED(_caller);
        }

        address tempOwner = temp[itemHash];
        address currentOwner = _caller;

        IEri.Item memory _item = tempOwners[itemHash][tempOwner];

        if (_item.owner == address(0)) {
            revert EriErrors.DOES_NOT_EXIST();
        }

        if (_item.owner != currentOwner) {
            revert EriErrors.ONLY_OWNER(currentOwner);
        }
        delete tempOwners[itemHash][tempOwner];
        delete temp[itemHash];

        return itemHash;
    }

    function _getItem(
        mapping(address => mapping(string => IEri.Item)) storage ownedItems,
        mapping(string => address) storage owners,
        string memory itemId
    ) public view returns (IEri.Item memory) {
        address user = owners[itemId];

        if (user == address(0)) {
            revert EriErrors.ITEM_DOESNT_EXIST(itemId);
        }

        return ownedItems[user][itemId]; // will likely make this a DTO so that you don't send all details of the item
    }

    function _verifyOwnership(
        mapping(address => mapping(string => IEri.Item)) storage ownedItems,
        mapping(string => address) storage owners,
        mapping(address => string) storage usernames,
        string memory itemId
    ) external view returns (IEri.Owner memory) {
        IEri.Item memory _item = _getItem(ownedItems, owners, itemId);

        return
            IEri.Owner({
                name: _item.name,
                itemId: _item.itemId,
                username: usernames[_item.owner],
                owner: _item.owner
            });
    }

    function _isOwner(
        mapping(address => mapping(string => IEri.Item)) storage ownedItems,
        address user,
        string memory itemId
    ) external view returns (bool) {
        return ownedItems[user][itemId].owner == user;
    }

    function _iOwn(
        mapping(address => mapping(string => IEri.Item)) storage ownedItems,
        address _caller,
        string memory itemId
    ) external view returns (bool) {
        return ownedItems[_caller][itemId].owner == _caller;
    }

    function isNotEmpty(string memory s) internal pure returns (bool) {
        return keccak256(bytes(s)) != keccak256(bytes(""));
    }

    function isRegistered(
        mapping(string => IEri.UserProfile) storage users,
        string memory _username
    ) internal view returns (bool) {
        return users[_username].isRegistered;
    }
}
