pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token_1 is ERC20 {
    constructor(uint256 _initialSupply) ERC20("Token 1", "T1") {
        _mint(msg.sender, _initialSupply);
    }
}