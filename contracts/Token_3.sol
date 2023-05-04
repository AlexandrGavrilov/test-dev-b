pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token_3 is ERC20 {
    constructor(uint256 _initialSupply) ERC20("Token 3", "T3") {
        _mint(msg.sender, _initialSupply);
    }
}