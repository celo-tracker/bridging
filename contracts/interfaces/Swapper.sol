// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface Swapper {
    function swap(
        address from,
        address to,
        uint256 requiredAmount
    ) external;

    function getOutputAmount(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256);
}
