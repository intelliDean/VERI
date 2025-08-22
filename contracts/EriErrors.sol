// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

contract EriErrors {
    error ONLY_OWNER(address);
    error ALREADY_REGISTERED(address);
    error ADDRESS_ZERO(address);
    error CODE_ALREADY_GENERATED();
    error UNAUTHORIZED(address);
    error ITEM_DOESNT_EXIST(string);
    error DOES_NOT_EXIST();
    error CONTRACT_DOEST_NOT_EXIST();
    error NAME_ALREADY_EXIST(string);
    error INVALID_SIGNATURE();
    error ITEM_CLAIMED_ALREADY(string);
    error ITEM_NOT_CLAIMED_YET();
    error NOT_REGISTERED(address);
    error NAME_NOT_AVAILABLE(string);
    error USER_DOES_NOT_EXIST(address);
    error CANNOT_GENERATE_CODE_FOR_YOURSELF(address);
    error USERNAME_MUST_BE_AT_LEAST_3_LETTERS();
    error INVALID_MANUFACTURER_NAME(string);
    error AUTHENTICITY_NOT_SET();
}