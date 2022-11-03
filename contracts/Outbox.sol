// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IWormhole.sol";
import "./interfaces/TokenBridge.sol";
import "./interfaces/Swapper.sol";

/// Sends tokens through the Wormhole token bridge, optionally making a swap before bridging.
/// Read the project README for more details on the whole flow.
contract Outbox is Ownable {
    event BridgeOut(
        address sender,
        bytes32 recipient,
        uint16 destinationChain,
        address token,
        uint256 amount,
        uint64 sequence
    );
    event InboxAdded(uint16 chainId, address inbox);

    /// Inbox address for each destination chain where messages will be processed.
    mapping(uint16 => address) public inboxes;

    /// Receives tokens from |msg.sender|, optionally swaps them and then sends them to the token bridge.
    function bridgeOut(
        TokenBridge bridge,
        Swapper swapper,
        bytes32 recipient,
        uint16 destinationChain,
        address inputToken,
        address tokenToBridge,
        uint256 amount,
        uint256 minAmountToBridge,
        uint32 nonce,
        address destinationBridgedToken,
        address destinationFinalToken,
        uint256 minFinalAmount,
        address destinationSwapper
    ) external payable returns (uint64 sequence) {
        require(
            inboxes[destinationChain] != address(0),
            "OB: Destination chain not supported"
        );
        // If |inputToken| is equal to |tokenToBridge|, then no swapping is necessary, so tokens are sent
        // to this contract. Otherwise, they are sent to the |swapper| contract for swapping.
        require(
            IERC20(inputToken).transferFrom(
                msg.sender,
                inputToken == tokenToBridge ? address(this) : address(swapper),
                amount
            ),
            "OB: Insufficient balance"
        );

        if (inputToken != tokenToBridge) {
            swapper.swap(inputToken, tokenToBridge, minAmountToBridge);
        }
        uint256 amountToBridge = IERC20(tokenToBridge).balanceOf(address(this));
        // Don't trust the swapper, verify the returned amount.
        require(
            amountToBridge >= minAmountToBridge,
            "OB: Insufficient amount to bridge"
        );

        // Extra info needed by the inbox to finish the bridging.
        bytes memory payload = abi.encode(
            recipient,
            // The following two fields will be equal if no swapping is necessary after bridging.
            destinationBridgedToken,
            destinationFinalToken,
            minFinalAmount,
            destinationSwapper
        );

        IERC20(tokenToBridge).approve(address(bridge), amountToBridge);
        sequence = bridge.transferTokensWithPayload(
            tokenToBridge,
            amountToBridge,
            destinationChain,
            bytes32(uint256(uint160(inboxes[destinationChain]))),
            nonce,
            payload
        );

        emit BridgeOut(
            msg.sender,
            recipient,
            destinationChain,
            inputToken,
            amount,
            sequence
        );
        return sequence;
    }

    function addInbox(uint16 chainId, address inbox) external onlyOwner {
        inboxes[chainId] = inbox;

        emit InboxAdded(chainId, inbox);
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
