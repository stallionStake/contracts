// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {FunctionsClient} from "@chainlink/contracts@0.8.0/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts@0.8.0/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts@0.8.0/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";

contract Oracle is FunctionsClient, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // State variables to store the last request ID, response, and error
    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // Event to log responses
    event Response(
        bytes32 indexed requestId,
        bytes response,
        bytes err
    );

    // Router address - Hardcoded for Mumbai
    // Check to get the router address for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    // address router = 0x6E2dc0F9DB014aE19888F539E59285D2Ea04244C;
    
    // Router address - Hardcoded for Arbitrum Sepolia
    address router = 0x234a5fb5Bd614a7AA2FfAB244D603abFA0Ac5C5C;

    // JavaScript source code
    // Fetch players' scores from our External Adapter Server
    // Documentation: https://github.com/stallionStake/ea-server/blob/main/.adapter.yml
    string source =
        "const date = args[0];"
        "const apiResponse = await Functions.makeHttpRequest({"
            "url: `https://localhost:8080/`,"
            "method: 'POST',"
            "body: JSON.stringify({"
                "id: 0,"
                "data: { 'date': ${date} }"
            "}),"
            "headers: {'Content-type': 'application/json'}"
        "};"
        "if (apiResponse.error) {"
        "throw Error('Request failed');"
        "}"
        "const { data } = apiResponse;"
        "return Functions.encodeString(data.data);";

    //Callback gas limit
    //uint32 gasLimit = 300000;
    uint32 gasLimit = 30000000;

    // donID - Hardcoded for Mumbai
    // Check to get the donID for your supported network https://docs.chain.link/chainlink-functions/supported-networks
    // bytes32 donID =
    //     0x66756e2d706f6c79676f6e2d6d756d6261692d31000000000000000000000000;

    // donID - Hardcoded for Arbitrum Sepolia
    bytes32 donID =
        0x66756e2d617262697472756d2d7365706f6c69612d3100000000000000000000;

    // Hardcoded for my subscription on Arbitrum Sepolia
    uint64 subscriptionId = 27;

    // State variable to store the returned information
    mapping(uint256 => mapping(uint256 => uint256)) public fantasyScores;

    // playerId => score
    mapping(uint256 => uint256) public currResult;

    /**
     * @notice Initializes the contract with the Chainlink router address and sets the contract owner
     */
    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    /**
     * @notice Sends an HTTP request for character information
     * @param args The arguments to pass to the HTTP request
     * @return requestId The ID of the request
     */
    function sendRequest(string[] calldata args) external onlyOwner returns (bytes32 requestId) {
        
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        // Send the request and store the request ID
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        return s_lastRequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill, returned by sendRequest()
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     * Either response or error parameter will be set, but never both
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        s_lastResponse = response;
        s_lastError = err;

        // Emit an event to log the response
        emit Response(requestId, s_lastResponse, s_lastError);
    }
}