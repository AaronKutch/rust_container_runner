pragma solidity ^0.8;

contract gravity {
    uint256 state_lastEventNonce;

    event TransactionBatchExecutedEvent(
        uint256 indexed _batchNonce,
        address indexed _token,
        uint256 _eventNonce
    );

    // constructor
    constructor() {
        state_lastEventNonce = 0;
    }

    function submitBatch(uint256 _batchNonce, address _tokenContract) public {
        state_lastEventNonce = state_lastEventNonce + 1;
        emit TransactionBatchExecutedEvent(
            _batchNonce,
            _tokenContract,
            state_lastEventNonce
        );
    }
}
