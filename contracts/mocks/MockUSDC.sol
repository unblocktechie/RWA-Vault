// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
  constructor() 
    ERC20("USDC", "USDC") {
        _mint(msg.sender, 10000000000000000000E6);
    }
  
  function decimals() public override pure returns (uint8) {
    return 6;
  }
}