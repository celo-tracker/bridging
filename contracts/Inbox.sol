// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWormhole.sol";
import "./interfaces/TokenBridge.sol";
import "./interfaces/Swapper.sol";

///
contract Inbox is Ownable {
    event BridgeIn(address indexed recipient, address token, uint256 amount);
    event SwapperAdded(address fromToken, address toToken, address swapper);

    TokenBridge public bridge;
    mapping(uint16 => address) outboxes;
    /// fromToken => toToken => Swapper
    mapping(address => mapping(address => Swapper)) swappers;

    constructor(TokenBridge _bridge) {
        bridge = _bridge;
    }

    function bridgeIn(bytes memory encodedVm) external {
        bytes memory payload = bridge.completeTransferWithPayload(encodedVm);
        BridgeStructs.TransferWithPayload memory transfer = bridge
            .parseTransferWithPayload(payload);

        (
            bytes32 recipientBytes,
            address destinationBridgedToken,
            address destinationFinalToken,
            uint256 minFinalAmount
        ) = abi.decode(transfer.payload, (bytes32, address, address, uint256));
        address recipient = address(uint160(uint256(recipientBytes)));

        if (destinationBridgedToken != destinationFinalToken) {
            Swapper swapper = swappers[destinationBridgedToken][
                destinationFinalToken
            ];
            require(address(swapper) != address(0), "IB: No swapper available");
            IERC20(destinationBridgedToken).transfer(
                address(swapper),
                IERC20(destinationBridgedToken).balanceOf(address(this))
            );
            swapper.swap(
                destinationBridgedToken,
                destinationFinalToken,
                minFinalAmount
            );
        }
        uint256 finalAmount = IERC20(destinationFinalToken).balanceOf(
            address(this)
        );
        require(
            finalAmount >= minFinalAmount,
            "IB: Not enough tokens received"
        );

        require(
            IERC20(destinationFinalToken).transfer(recipient, finalAmount),
            "IB: Final transfer failed"
        );

        emit BridgeIn(recipient, destinationFinalToken, finalAmount);
    }

    function addSwapper(
        address fromToken,
        address toToken,
        Swapper swapper
    ) external onlyOwner {
        swappers[fromToken][toToken] = swapper;
        emit SwapperAdded(fromToken, toToken, address(swapper));
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
