pragma solidity ^0.8;

contract gravity {
    uint256 state_lastEventNonce;

	event TransactionBatchExecutedEvent(
		uint256 indexed _batchNonce,
		address indexed _token,
		uint256 _eventNonce
	);
	event SendToCosmosEvent(
		address indexed _tokenContract,
		address indexed _sender,
		string _destination,
		uint256 _amount,
		uint256 _eventNonce
	);
	event ERC20DeployedEvent(
		// FYI: Can't index on a string without doing a bunch of weird stuff
		string _cosmosDenom,
		address indexed _tokenContract,
		string _name,
		string _symbol,
		uint8 _decimals,
		uint256 _eventNonce
	);
	event ValsetUpdatedEvent(
		uint256 indexed _newValsetNonce,
		uint256 _eventNonce,
		uint256 _rewardAmount,
		address _rewardToken,
		address[] _validators,
		uint256[] _powers
	);
	event LogicCallEvent(
		bytes32 _invalidationId,
		uint256 _invalidationNonce,
		bytes _returnData,
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

    function emitValsetUpdatedEvent(uint256 _batchNonce, address _tokenContract) public {
        /*emit ValsetUpdatedEvent(
            0,
            0,
            0,
            address(0),
            [address(0)],
            [0]
        );*/
    }
}
