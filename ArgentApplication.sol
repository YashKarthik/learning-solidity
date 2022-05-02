//SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IApply {
    function applyUsingEmail(bytes32 emailHash) external;
    function getApplicationID(string memory email) external view returns (uint256);
}

contract ApplyToArgent {
    bytes32 public emailHash;
    IApply public applyContract = IApply(0x78D36BA446D73Be73f32e2Cc181A82E3ba5fEf2E);

    constructor(string memory _email) {
        emailHash = keccak256(abi.encodePacked(_email));
    }

    function applyInit() public {
        applyContract.applyUsingEmail(emailHash);
    }

    function getAppId(string memory _email) public view returns (uint256) {
        return applyContract.getApplicationID(_email);
    }

}
