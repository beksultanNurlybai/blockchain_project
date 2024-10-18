// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Marketplace {
    struct Resource {
        uint256 cpuId;
        uint256 gpuId;
        uint16 ramSize;
        string storageType;
        uint16 storageSize;
        uint256 price;
        address renter;
        address owner;
    }
    struct CPU {
        string name;
        uint64 frequency;
        uint16 coreNum;
    }
    struct GPU {
        string name;
        uint64 frequency;
        uint16 memorySize;
    }

    uint256 public resourcesCount = 0;
    mapping(uint256 => Resource) public resources;
    uint256[] public resourceIds;
    CPU[] public cpus;
    GPU[] public gpus;
    mapping(address => uint256[]) public rentersResources;
    mapping(address => uint256[]) public ownersResources;

    constructor() {
        cpus.push(CPU("Intel Core i9-11900K", 3500000000, 8));
        cpus.push(CPU("AMD Ryzen 9 5900X", 3700000000, 12));
        cpus.push(CPU("Intel Core i7-11700K", 3600000000, 8));
        cpus.push(CPU("AMD Ryzen 7 5800X", 3800000000, 8));
        cpus.push(CPU("Apple M1 Max", 3200000000, 10));

        gpus.push(GPU("NVIDIA RTX 3090", 1400000000, 24000));
        gpus.push(GPU("AMD Radeon RX 6900 XT", 1825000000, 16000));
        gpus.push(GPU("NVIDIA RTX 3080", 1710000000, 10000));
        gpus.push(GPU("AMD Radeon RX 6800 XT", 2015000000, 16000));
        gpus.push(GPU("NVIDIA RTX 3070", 1500000000, 8000));
    }

    event ResourceCreated(uint256 resourceId, uint256 price, address owner);
    event ResourceChanged(uint256 resourceId, uint256 price, address owner);
    event ResourceDeleted(uint256 resourceId, uint256 price, address owner);
    event ResourceRented(uint256 resourceId, uint256 price,  address renter);
    event RentCancelled(uint256 resourceId, address renter);

    function createResource (
        uint256 cpuId_,
        uint256 gpuId_,
        uint16 ramSize_,
        string memory storageType_,
        uint16 storageSize_,
        uint256 price_
    ) public {
        require(price_ > 0, "Price must be greater than zero.");
        require(cpuId_ >= 0 && cpuId_ < cpus.length, "Incorrect CPU ID.");
        require(gpuId_ >= 0 && gpuId_ < gpus.length, "Incorrect GPU ID.");

        resources[resourcesCount] = Resource({
            cpuId: cpuId_,
            gpuId: gpuId_,
            ramSize: ramSize_,
            storageType: storageType_,
            storageSize: storageSize_,
            price: price_,
            renter: address(0),
            owner: msg.sender
        });
        resourceIds.push(resourcesCount);

        emit ResourceCreated (resourcesCount, price_, msg.sender);
        resourcesCount++;
    }

    function changeResource (
        uint256 resourceId_,
        uint256 cpuId_,
        uint256 gpuId_,
        uint16 ramSize_,
        string memory storageType_,
        uint16 storageSize_,
        uint256 price_
    ) public {
        require(resources[resourceId_].owner != address(0), "Incorrect resource ID.");
        require(resources[resourceId_].renter == address(0), "Resource is currently rented.");
        require(price_ > 0, "Price must be greater than zero.");
        require(cpuId_ < cpus.length, "Incorrect CPU ID.");
        require(gpuId_ < gpus.length, "Incorrect GPU ID.");

        resources[resourceId_] = Resource({
            cpuId: cpuId_,
            gpuId: gpuId_,
            ramSize: ramSize_,
            storageType: storageType_,
            storageSize: storageSize_,
            price: price_,
            renter: address(0),
            owner: msg.sender
        });

        emit ResourceChanged(resourceId_, price_, msg.sender);
    }

    function deleteResource(uint256 resourceId_) public {
        require(resources[resourceId_].owner != address(0), "Incorrect resource ID.");
        require(resources[resourceId_].renter == address(0), "Resource is currently rented.");
        
        uint256 price = resources[resourceId_].price;
        address owner = resources[resourceId_].owner;
        delete resources[resourceId_];
        for (uint256 i = 0; i < resourceIds.length; i++) {
            if (resourceIds[i] == resourceId_) {
                resourceIds[i] = resourceIds[resourceIds.length - 1];
                resourceIds.pop();
                break;
            }
        }
        
        emit ResourceDeleted(resourceId_, price, owner);
    }

    function getResource(uint256 resourceId_) public view returns (
        uint256 cpuId,
        uint256 gpuId,
        uint16 ramSize,
        string memory storageType,
        uint16 storageSize,
        uint256 price_,
        address renter,
        address owner
    ) {
        require(resources[resourceId_].owner != address(0), "Incorrect resource ID.");
        
        Resource storage resource = resources[resourceId_];
        
        return (
            resource.cpuId,
            resource.gpuId,
            resource.ramSize,
            resource.storageType,
            resource.storageSize,
            resource.price,
            resource.renter,
            resource.owner
        );
    }

    function getResourceIds() public view returns (uint256[] memory) {
        return resourceIds;
    }

    function getResourceNum() public view returns (uint256) {
        return resourceIds.length;
    }

    function rentResource(uint256 resourceId_) public payable {
        require(resources[resourceId_].owner != address(0), "Incorrect resource ID.");
        require(resources[resourceId_].renter == address(0), "Resource is already rented.");
        require(resources[resourceId_].owner != msg.sender, "Owner cannot rent their own resource.");
        require(resources[resourceId_].price == msg.value, "Incorrect payment amount.");
        
        (bool sent, ) = payable(resources[resourceId_].owner).call{value: msg.value}("");
        require(sent, "Failed to transfer payment to owner.");
        
        resources[resourceId_].renter = msg.sender;
        
        emit ResourceRented(resourceId_, msg.value, msg.sender);
    }


    function cancelRent(uint256 resourceId_) public {
        require(resources[resourceId_].owner != address(0), "Incorrect resource ID.");
        require(resources[resourceId_].renter == msg.sender, "You are not the renter.");
        
        resources[resourceId_].renter = address(0);
        emit RentCancelled(resourceId_, msg.sender);
    }
}
