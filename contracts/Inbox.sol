// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWormhole.sol";
import "./interfaces/TokenBridge.sol";
import "./interfaces/Swapper.sol";

///
contract Inbox is Ownable {
    event BridgeIn(
        address indexed recipient,
        address token,
        uint256 amount,
        bool swapOverride
    );
    event BridgeInWithoutSwapping(
        address indexed recipient,
        address token,
        uint256 amount
    );
    event SwapperAdded(address fromToken, address toToken, address swapper);

    TokenBridge public bridge;

    constructor(TokenBridge _bridge) {
        bridge = _bridge;
    }

    function bridgeIn(bytes memory encodedVm) external {
        (
            ,
            address recipient,
            address bridgedToken,
            address finalToken,
            uint256 minFinalAmount,
            address swapper
        ) = decodeAndVerifyBridgeInfo(encodedVm);

        if (bridgedToken != finalToken) {
            require(swapper != address(0), "IB: No swapper available");
            IERC20(bridgedToken).transfer(
                swapper,
                IERC20(bridgedToken).balanceOf(address(this))
            );
            Swapper(swapper).swap(bridgedToken, finalToken, minFinalAmount);
        }
        uint256 finalAmount = IERC20(finalToken).balanceOf(address(this));
        require(
            finalAmount >= minFinalAmount,
            "IB: Not enough tokens received"
        );

        require(
            IERC20(finalToken).transfer(recipient, finalAmount),
            "IB: Final transfer failed"
        );

        emit BridgeIn(recipient, finalToken, finalAmount, false);
    }

    function bridgeInWithOverrides(
        bytes memory encodedVm,
        Swapper swapper,
        address finalToken,
        uint256 minFinalAmount
    ) external {
        (
            address sender,
            address recipient,
            address bridgedToken,
            ,
            ,

        ) = decodeAndVerifyBridgeInfo(encodedVm);

        require(
            msg.sender == recipient || msg.sender == sender,
            "IB: Only sender and recipient can use overrides"
        );

        IERC20(bridgedToken).transfer(
            address(swapper),
            IERC20(bridgedToken).balanceOf(address(this))
        );
        Swapper(swapper).swap(bridgedToken, finalToken, minFinalAmount);

        uint256 finalAmount = IERC20(finalToken).balanceOf(address(this));
        require(
            finalAmount >= minFinalAmount,
            "IB: Not enough tokens received"
        );

        require(
            IERC20(finalToken).transfer(recipient, finalAmount),
            "IB: Final transfer failed"
        );

        emit BridgeIn(recipient, finalToken, finalAmount, true);
    }

    function bridgeInWithoutSwapping(bytes memory encodedVm) external {
        (
            ,
            address recipient,
            address bridgedToken,
            ,
            ,

        ) = decodeAndVerifyBridgeInfo(encodedVm);

        uint256 amount = IERC20(bridgedToken).balanceOf(address(this));
        require(
            IERC20(bridgedToken).transfer(recipient, amount),
            "IB: Transfer failed"
        );

        emit BridgeInWithoutSwapping(recipient, bridgedToken, amount);
    }

    function decodeAndVerifyBridgeInfo(bytes memory encodedVm)
        internal
        returns (
            address sender,
            address recipient,
            address bridgedToken,
            address finalToken,
            uint256 minAmount,
            address swapper
        )
    {
        bytes memory payload = bridge.completeTransferWithPayload(encodedVm);
        BridgeStructs.TransferWithPayload memory transfer = bridge
            .parseTransferWithPayload(payload);

        (
            bytes32 recipientBytes,
            address _bridgedToken,
            address _finalToken,
            uint256 _minAmount,
            address _swapper
        ) = abi.decode(
                transfer.payload,
                (bytes32, address, address, uint256, address)
            );

        sender = address(uint160(uint256(transfer.fromAddress)));
        recipient = address(uint160(uint256(recipientBytes)));
        bridgedToken = _bridgedToken;
        finalToken = _finalToken;
        minAmount = _minAmount;
        swapper = _swapper;
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
