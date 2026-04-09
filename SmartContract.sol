// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract RiceSupplyChain {

    // ENUM for product status
    enum Status { Created, InTransit, Delivered }

    // STRUCT for product details
    struct Product {
        uint256 productId;
        string name;
        uint256 quantity;
        string origin;
        uint256 dateCreated;
        address currentOwner;
        Status status;
    }

    // STRUCT for ownership history
    struct History {
        address from;
        address to;
        uint256 timestamp;
        Status status;
    }

    // STATE VARIABLES
    address public farmer;
    address public distributor;
    uint256 public productCounter;

    mapping(uint256 => Product) public products;
    mapping(uint256 => History[]) public productHistory;

    // MODIFIERS (Access Control)
    modifier onlyFarmer() {
        require(msg.sender == farmer, "Only farmer allowed");
        _;
    }

    modifier onlyAuthorized() {
        require(
            msg.sender == farmer || msg.sender == distributor,
            "Not authorized"
        );
        _;
    }

    // CONSTRUCTOR
    constructor(address _distributor) {
        farmer = msg.sender;
        distributor = _distributor;
    }

    // 1. PRODUCT REGISTRATION
    function registerProduct(
        string memory _name,
        uint256 _quantity,
        string memory _origin
    ) public onlyFarmer {

        productCounter++;

        products[productCounter] = Product({
            productId: productCounter,
            name: _name,
            quantity: _quantity,
            origin: _origin,
            dateCreated: block.timestamp,
            currentOwner: msg.sender,
            status: Status.Created
        });

        // Save history
        productHistory[productCounter].push(
            History(address(0), msg.sender, block.timestamp, Status.Created)
        );
    }

    // 2 & 4. TRANSFER OWNERSHIP
    function transferOwnership(uint256 _productId) public onlyAuthorized {

        Product storage product = products[_productId];

        require(product.productId != 0, "Product does not exist");
        require(product.status != Status.Delivered, "Already delivered");

        address previousOwner = product.currentOwner;

        // Transfer to distributor
        if (msg.sender == farmer) {
            product.currentOwner = distributor;
            product.status = Status.InTransit;
        } 
        // Mark as delivered
        else if (msg.sender == distributor) {
            product.status = Status.Delivered;
        }

        // Record history
        productHistory[_productId].push(
            History(previousOwner, product.currentOwner, block.timestamp, product.status)
        );
    }

    // 6. VIEW PRODUCT DETAILS
    function getProduct(uint256 _productId)
        public
        view
        returns (
            uint256,
            string memory,
            uint256,
            string memory,
            uint256,
            address,
            Status
        )
    {
        Product memory p = products[_productId];
        return (
            p.productId,
            p.name,
            p.quantity,
            p.origin,
            p.dateCreated,
            p.currentOwner,
            p.status
        );
    }

    // VIEW HISTORY
    function getProductHistory(uint256 _productId)
        public
        view
        returns (History[] memory)
    {
        return productHistory[_productId];
    }
}