// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface ConduitControllerInterface {

    struct ConduitProperties {
        bytes32 key;
        address owner;
        address potentialOwner;
        address[] channels;
        mapping(address => uint256) channelIndexesPlusOne;
    }

    event NewConduit(address conduit, bytes32 conduitKey);

    event OwnershipTransferred(
        address indexed conduit,
        address indexed previousOwner,
        address indexed newOwner
    );

    event PotentialOwnerUpdated(address indexed newPotentiaOwner);

    error InvalidCreator();
    error InvalidInitialOwner();
    error  NewPotentialOwnerAlreadySet(
        address conduit,
        address newPotentiaOwner
    );
    error NoPotentialOwnerCurrentlySet(address conduit);
    error NoConduit();
    error ConduitAlreadyExist(address conduit);
    error CallerIsNotOwner(address conduit);
    error NewPotentialownerIsZeroAddress(address conduit);
    error CallerIsNotNewPotentiaOwner(address conduit);
    error ChannelOutOfRange(address conduit);


    function ownerOf(address conduit) external view returns (address owner);
    function transferownership(address conduit, address newPotentialOwner) external;
    function cancelOwnershipTransfer(address conduit) external;
    function acceptOwnership(address conduit) external;
    
    function createConduit(bytes32 conduitKey, address initialOwner) 
        external returns (address conduit);
    function getKey(address conduit) external view returns (bytes32 conduitKey);
    function getConduit(bytes32 conduitKey) external view 
        returns (address conduit, bool exists);
    function getPotentialOwner(address conduit) external view returns (address potentialOwner);

    function updateChannel(address conduit, address channel, bool isOpen) external;
    function getChannelsStatus(address conduit, address channel)
        external view returns (bool isOpen);
    function getTotalChannels(address conduit) external returns (uint256 totalChannels);
    function getChannel(address conduit, uint256 channelIndex) 
        external view returns (address channel);
    function getChannels(address conduit) external view returns (address[] memory channels);

    function getConduitCodeHashs() external view
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}