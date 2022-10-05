// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/Swapper.sol";
import "../interfaces/uniswapV2/IUniswapV2Router02.sol";

///
contract QuickswapSwapper is Swapper, Ownable {
    IUniswapV2Router02 router;

    constructor(IUniswapV2Router02 _router) {
        router = _router;
    }

    function swap(
        address from,
        address to,
        uint256 requiredAmount
    ) external {
        uint256 swapAmount = IERC20(from).balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;

        IERC20(from).approve(address(router), swapAmount);
        router.swapExactTokensForTokens(
            swapAmount,
            requiredAmount,
            path,
            msg.sender,
            block.timestamp
        );
    }

    function getOutputAmount(
        address from,
        address to,
        uint256 amount
    ) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = from;
        path[1] = to;
        uint256[] memory amounts = router.getAmountsOut(amount, path);
        return amounts[1];
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
