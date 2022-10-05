// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/Swapper.sol";
import "../interfaces/curve/AavePool.sol";

/// Swaps tokens using Polygon's aave pool which holds Aave lent USDC, DAI and USDT.
/// They can be swapped using the underlying_x functions.
contract CurveAaveSwapper is Swapper, Ownable {
    AavePool public aavePool;

    constructor(AavePool _aavePool) {
        aavePool = _aavePool;
    }

    function swap(
        address from,
        address to,
        uint256 requiredAmount
    ) external {
        uint256 swapAmount = IERC20(from).balanceOf(address(this));

        require(
            IERC20(from).approve(address(aavePool), swapAmount),
            "MobiusSwapper: approve failed!"
        );
        
        (int128 i, int128 j) = findIndexes(from, to);
        aavePool.exchange_underlying(i, j, swapAmount, requiredAmount);

        IERC20(to).transfer(msg.sender, IERC20(to).balanceOf(address(this)));
    }

    function getOutputAmount(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256) {
        (int128 i, int128 j) = findIndexes(from, to);
        return aavePool.get_dy_underlying(i, j, amount);
    }

    function findIndexes(address t0, address t1)
        internal
        view
        returns (int128 i, int128 j)
    {
        for (uint16 x = 0; x <= 2; x++) {
            address token = aavePool.underlying_coins(x);
            if (t0 == token) {
                i = int16(x);
            } else if (t1 == token) {
                j = int16(x);
            }
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
