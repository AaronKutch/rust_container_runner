pragma solidity ^0.8;

contract CosmosERC20 {
	uint256 MAX_UINT = 2**256 - 1;
	uint8 private cosmosDecimals;
	address private gravityAddress;

	// This override ensures we return the proper number of decimals
	// for the cosmos token
	function decimals() public view virtual returns (uint8) {
		return cosmosDecimals;
	}

	// This is not an accurate total supply. Instead this is the total supply
	// of the given cosmos asset on Ethereum at this moment in time. Keeping
	// a totally accurate supply would require constant updates from the Cosmos
	// side, while in theory this could be piggy-backed on some existing bridge
	// operation it's a lot of complextiy to add so we chose to forgoe it.
	function totalSupply() public view virtual returns (uint256) {
		return MAX_UINT;// - balanceOf(gravityAddress);
	}

	constructor(
		address _gravityAddress,
		string memory _name,
		string memory _symbol,
		uint8 _decimals
	) {
		cosmosDecimals = _decimals;
		gravityAddress = _gravityAddress;
		//_mint(_gravityAddress, MAX_UINT);
	}
}

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
		address indexed _tokenContract,
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
		// Deploy an ERC20 with entire supply granted to Gravity.sol
		CosmosERC20 erc20 = new CosmosERC20(address(this), _name, _symbol, _decimals);

		// Fire an event to let the Cosmos module know
		state_lastEventNonce = state_lastEventNonce + 1;
		emit ERC20DeployedEvent(
			_cosmosDenom,
			address(erc20),
			_name,
			_symbol,
			_decimals,
			state_lastEventNonce
		);
	}
}
