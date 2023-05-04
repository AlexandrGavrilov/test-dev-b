pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Token_2 is ERC20 {
    constructor(uint256 _initialSupply) ERC20("Token 2", "T2") {
        _mint(msg.sender, _initialSupply);
    }
}