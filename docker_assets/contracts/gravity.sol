pragma solidity 0.8.10;

contract Greeting {
    address creator;
    string message;
    uint256 state_lastEventNonce;

    event TransactionBatchExecutedEvent(
		uint256 indexed _batchNonce,
		address indexed _token,
		uint256 _eventNonce
	);

    // constructor
    function Greeting(string _message) {
        message = _message;
        creator = msg.sender;
    }

    function greet() constant returns (string) {
        return message;
    }

    function setGreeting(string _message) {
        message = _message;
    }

    function submitBatch(
		uint256 _batchNonce,
		address _tokenContract,
	) external nonReentrant {
        state_lastEventNonce = state_lastEventNonce + 1;
        emit TransactionBatchExecutedEvent(_batchNonce, _tokenContract, state_lastEventNonce);
	}
}
