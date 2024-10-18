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

    uint256 private resourcesCount = 0;
    mapping(uint256 => Resource) private resources;
    uint256[] private resourceIds;
    CPU[] private cpus;
    GPU[] private gpus;
    mapping(address => uint256[]) private rentersResources;
    mapping(address => uint256[]) private ownersResources;

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
        ownersResources[msg.sender].push(resourcesCount);

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
        require(resources[resourceId_].owner == msg.sender, "Only creator can delete own resource.");
        require(resources[resourceId_].renter == address(0), "Resource is currently rented.");
        
        uint256 price = resources[resourceId_].price;
        address owner = resources[resourceId_].owner;
        delete resources[resourceId_];
        deleteResourceId(resourceIds, resourceId_);
        deleteResourceId(ownersResources[msg.sender], resourceId_);
        
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

    function rentResource(uint256 resourceId_) public payable {
        require(resources[resourceId_].owner != address(0), "Incorrect resource ID.");
        require(resources[resourceId_].renter == address(0), "Resource is already rented.");
        require(resources[resourceId_].owner != msg.sender, "Owner cannot rent their own resource.");
        require(resources[resourceId_].price == msg.value, "Incorrect payment amount.");
        
        (bool sent, ) = payable(resources[resourceId_].owner).call{value: msg.value}("");
        require(sent, "Failed to transfer payment to owner.");
        
        resources[resourceId_].renter = msg.sender;
        rentersResources[msg.sender].push(resourceId_);
        
        emit ResourceRented(resourceId_, msg.value, msg.sender);
    }

    function cancelRent(uint256 resourceId_) public {
        require(resources[resourceId_].owner != address(0), "Incorrect resource ID.");
        require(resources[resourceId_].renter == msg.sender, "You are not the renter.");
        
        resources[resourceId_].renter = address(0);
        deleteResourceId(rentersResources[msg.sender], resourceId_);
        
        emit RentCancelled(resourceId_, msg.sender);
    }

    function getResourceIds() public view returns (uint256[] memory) {
        return resourceIds;
    }

    function getResourceNum() public view returns (uint256) {
        return resourceIds.length;
    }

    function getRenterResources (address renter) public view returns (uint256[] memory) {
        return rentersResources[renter];
    }

    function getOwnerResources (address owner) public view returns (uint256[] memory) {
        return ownersResources[owner];
    }

    function getCpus() public view returns (string[] memory, uint64[] memory, uint16[] memory) {
        string[] memory names = new string[](cpus.length);
        uint64[] memory frequencies = new uint64[](cpus.length);
        uint16[] memory coreNums = new uint16[](cpus.length);
        
        for (uint256 i = 0; i < cpus.length; i++) {
            names[i] = cpus[i].name;
            frequencies[i] = cpus[i].frequency;
            coreNums[i] = cpus[i].coreNum;
        }

        return (names, frequencies, coreNums);
    }

    function getGpus() public view returns (string[] memory, uint64[] memory, uint16[] memory) {
        string[] memory names = new string[](gpus.length);
        uint64[] memory frequencies = new uint64[](gpus.length);
        uint16[] memory memorySizes = new uint16[](gpus.length);

        for (uint256 i = 0; i < cpus.length; i++) {
            names[i] = cpus[i].name;
            frequencies[i] = cpus[i].frequency;
            memorySizes[i] = cpus[i].coreNum;
        }

        return (names, frequencies, memorySizes);
    }

    function deleteResourceId(uint256[] storage arr, uint256 id) private {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == id) {
                arr[i] = arr[arr.length - 1];
                arr.pop();
                break;
            }
        }
    }
}
