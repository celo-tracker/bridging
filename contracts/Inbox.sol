// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWormhole.sol";
import "./interfaces/TokenBridge.sol";
import "./interfaces/Swapper.sol";

/// Receives tokens through the Wormhole token bridge, optionally making a swap after bridging.
/// Read the project README for more details on the whole flow.
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

    /// Receives tokens bridged, optionally swaps them and sends the final tokens to the recipient.
    function bridgeIn(bytes memory encodedVm) external {
        (
            ,
            address recipient,
            address bridgedToken,
            address finalToken,
            uint256 minFinalAmount,
            address swapper
        ) = decodeAndVerifyBridgeInfo(encodedVm);

        // If necessary, swap bridged tokens for native ones.
        if (bridgedToken != finalToken) {
            require(swapper != address(0), "IB: No swapper available");
            IERC20(bridgedToken).transfer(
                swapper,
                IERC20(bridgedToken).balanceOf(address(this))
            );
            Swapper(swapper).swap(bridgedToken, finalToken, minFinalAmount);
        }
        uint256 finalAmount = IERC20(finalToken).balanceOf(address(this));
        // Don't trust the swapper, verify.
        require(
            finalAmount >= minFinalAmount,
            "IB: Not enough tokens received"
        );

        // Send the resulting tokens to the recipient.
        require(
            IERC20(finalToken).transfer(recipient, finalAmount),
            "IB: Final transfer failed"
        );

        emit BridgeIn(recipient, finalToken, finalAmount, false);
    }

    /// Similar to |bridgeIn| but instead of using the parameters on the payload, use the ones
    /// passed as parameter. Can only be called by the sender or recipient. Notmeant to be used
    /// frequently, just here in case there's an issue with the parameters.
    /// For example, the swapper might not find enough liquidity to perform the swap and satisfy
    /// |minFinalAmount| so we use a different one or different |minFinalAmount|.
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

        // Swap the bridged token using the overrides.
        IERC20(bridgedToken).transfer(
            address(swapper),
            IERC20(bridgedToken).balanceOf(address(this))
        );
        Swapper(swapper).swap(bridgedToken, finalToken, minFinalAmount);

        uint256 finalAmount = IERC20(finalToken).balanceOf(address(this));
        // Don't trust the swapper, verify.
        require(
            finalAmount >= minFinalAmount,
            "IB: Not enough tokens received"
        );

        // Send the resulting tokens to the recipient.
        require(
            IERC20(finalToken).transfer(recipient, finalAmount),
            "IB: Final transfer failed"
        );

        emit BridgeIn(recipient, finalToken, finalAmount, true);
    }

    /// Similar to |bridgeIn| but completely ignores the swapping. This just receives the 
    /// bridged tokens and sends them to the recipient.
    /// Not meant to be used frequently, only if there is some issue with the swapper and 
    /// we don't want to or can't use a different one.
    /// Note that this can be called by anyone, not just recipient/sender. This isn't 
    /// dangerous but someone could call this function to annoy users. They would 
    /// be paying for gas and have no benefit, so we hope this won't happen but if it does
    /// we can simply deploy a new Inbox with the sender/recipient check here.
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

    /// Make sure |encodedVm| is correct and receive the bridged tokens from the token bridge.
    /// Also parse the extra fields passed through the payload field.
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

    /// Shouldn't be necessary, this contract doesn't hold funds. Here just in case of emergency.
    function exec(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyOwner {
        (bool success, bytes memory reason) = target.call{value: value}(data);
        require(success, string(reason));
    }
}
