// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/Swapper.sol";
import "../interfaces/stableswap/ISwap.sol";

///
contract MobiusSwapper is Swapper, Ownable {
    address public poolAddress;

    constructor(address _poolAddress) {
        poolAddress = _poolAddress;
    }

    function swap(
        address from,
        address to,
        uint256 requiredAmount
    ) external {
        uint256 swapAmount = IERC20(from).balanceOf(address(this));

        require(
            IERC20(from).approve(poolAddress, swapAmount),
            "MobiusSwapper: approve failed!"
        );
        ISwap swapPool = ISwap(poolAddress);
        uint256 outputAmount;
        if (swapPool.getToken(0) == from) {
            outputAmount = swapPool.swap(
                0,
                1,
                swapAmount,
                requiredAmount,
                block.timestamp
            );
        } else {
            outputAmount = swapPool.swap(
                1,
                0,
                swapAmount,
                requiredAmount,
                block.timestamp
            );
        }
        require(
            IERC20(to).transfer(msg.sender, outputAmount),
            "MobiusSwapper: transfer failed!"
        );
    }

    function getOutputAmount(
        address from,
        address,
        uint256 amount
    ) external view returns (uint256) {
        ISwap swapPool = ISwap(poolAddress);
        if (swapPool.getToken(0) == from) {
            return swapPool.calculateSwap(0, 1, amount);
        } else {
            return swapPool.calculateSwap(1, 0, amount);
        }
    }

    /// Shouldn't be necessary, here just in case of emergency.
    function exec(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyOwner {
        (bool success, bytes memory reason) = target.call{value: value}(data);
        require(success, string(reason));
    }
}
