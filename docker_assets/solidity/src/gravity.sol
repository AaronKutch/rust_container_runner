pragma solidity ^0.8;

contract gravity {
	uint256 public state_lastValsetNonce = 0;
    uint256 public state_lastEventNonce = 1;

    event TransactionBatchExecutedEvent(
        uint256 indexed _batchNonce,
        address indexed _token,
        uint256 _eventNonce
    );
    event ERC20DeployedEvent(
        // FYI: Can't index on a string without doing a bunch of weird stuff
        string _cosmosDenom,
        string _name,
        string _symbol,
        uint8 _decimals,
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

    function deployERC20(
		string calldata _cosmosDenom,
		string calldata _name,
		string calldata _symbol,
		uint8 _decimals
	) external {
		state_lastEventNonce = state_lastEventNonce + 1;
		emit ERC20DeployedEvent(
			_cosmosDenom,
			_name,
			_symbol,
			_decimals,
			state_lastEventNonce
		);
	}
}
