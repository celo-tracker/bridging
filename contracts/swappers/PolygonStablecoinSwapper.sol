// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/Swapper.sol";
import "../interfaces/uniswapV2/IUniswapV2Router02.sol";

/// Swapper that combines the USDC<->USDCet swapper and the stablecoin swapper between USDC/USDCT/DAI
/// to allow swaps between USDCet and the other 3 stablecoins.
contract PolygonStablecoinSwapper is Swapper, Ownable {
    Swapper usdcSwapper;
    Swapper stablecoinSwapper;
    address usdcAddress;
    address usdcetAddress;

    constructor(
        Swapper _usdcSwapper,
        Swapper _stablecoinSwapper,
        address _usdcAddress,
        address _usdcetAddress
    ) {
        usdcSwapper = _usdcSwapper;
        stablecoinSwapper = _stablecoinSwapper;
        usdcAddress = _usdcAddress;
        usdcetAddress = _usdcetAddress;
    }

    function swap(
        address from,
        address to,
        uint256 requiredAmount
    ) external {
        if (from == usdcetAddress) {
            // If going USDCet -> stable, first swap USDCet for USDC
            uint256 swapAmount = IERC20(from).balanceOf(address(this));
            IERC20(from).transfer(address(usdcSwapper), swapAmount);
            usdcSwapper.swap(from, usdcAddress, 0);

            uint256 swappedAmount = IERC20(usdcAddress).balanceOf(
                address(this)
            );
            if (to == usdcAddress) {
                // If the final destination is USDC, transfer it back
                require(
                    swappedAmount >= requiredAmount,
                    "PSS: Insufficient swapped amount"
                );
                IERC20(to).transfer(msg.sender, swappedAmount);
            } else {
                // If the final destination is NOT USDC, use the stablecoinSwapper to swap for it and transfer it back.
                IERC20(usdcAddress).transfer(
                    address(stablecoinSwapper),
                    swappedAmount
                );
                stablecoinSwapper.swap(usdcAddress, to, requiredAmount);
                IERC20(to).transfer(
                    msg.sender,
                    IERC20(to).balanceOf(address(this))
                );
            }
        } else {
            require(to == usdcetAddress, "PSS: from or to must be USDCet");
            // If going stable -> USDCet, first check if stable is USDC. If not, swap for USDC.
            if (from != usdcAddress) {
                IERC20(from).transfer(
                    address(stablecoinSwapper),
                    IERC20(from).balanceOf(address(this))
                );
                stablecoinSwapper.swap(from, usdcAddress, 0);
            }
            // Now swap USDC for USDCet and transfer it back.
            IERC20(usdcAddress).transfer(
                address(usdcSwapper),
                IERC20(usdcAddress).balanceOf(address(this))
            );
            usdcSwapper.swap(usdcAddress, to, requiredAmount);
            IERC20(to).transfer(
                msg.sender,
                IERC20(to).balanceOf(address(this))
            );
        }
    }

    function getOutputAmount(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256) {
        if (from == usdcetAddress) {
            uint256 usdcAmount = usdcSwapper.getOutputAmount(
                from,
                usdcAddress,
                amount
            );
            if (to == usdcAddress) {
                return usdcAmount;
            } else {
                return
                    stablecoinSwapper.getOutputAmount(
                        usdcAddress,
                        to,
                        usdcAmount
                    );
            }
        } else {
            uint256 usdcAmount = from == usdcAddress
                ? amount
                : stablecoinSwapper.getOutputAmount(from, usdcAddress, amount);
            return usdcSwapper.getOutputAmount(usdcAddress, to, usdcAmount);
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
