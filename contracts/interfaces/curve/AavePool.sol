// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface AavePool {
    function underlying_coins(uint256 index) external view returns (address);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 minDy
    ) external returns (uint256);
}
