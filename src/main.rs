#![allow(unused_must_use)]
use std::{env, path::PathBuf, time::Duration};

use clarity::{
    abi::Token, address::Address as EthAddress, u256, PrivateKey as EthPrivateKey, Transaction,
    Uint256,
};
use ethers::{
    prelude::{ContractFactory, SignerMiddleware},
    signers::LocalWallet,
    solc::{Project, ProjectPathsConfig},
};
use futures::future::join_all;
use lazy_static::lazy_static;
use web30::{client::Web3, jsonrpc::error::Web3Error, types::SendTxOption};

lazy_static! {
    // this key is the private key for the public key defined in tests/assets/ETHGenesis.json
    // where the full node / miner sends its rewards. Therefore it's always going
    // to have a lot of ETH to pay for things like contract deployments
    static ref MINER_PRIVATE_KEY: EthPrivateKey = env::var("MINER_PRIVATE_KEY").unwrap_or_else(|_|
        "0xb1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7".to_owned()
            ).parse()
            .unwrap();
    static ref MINER_ADDRESS: EthAddress = MINER_PRIVATE_KEY.to_address();
}
pub const HIGH_GAS_PRICE: Uint256 = u256!(321000000000);

pub const TEST_GAS_LIMIT: Uint256 = u256!(2_000_000);

pub const ETH_NODE: &str = "http://proxy:9090/solana";
pub const CHAIN_ID: u64 = 111;
pub const WALLET: &str = "b1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7";

#[tokio::main]
pub async fn main() {
    //dbg!(u256!(50000000000000000000000000).checked_sub(
    //u256!(39999999993700000000000000)).unwrap());
    //panic!();
    //300000000000
    //6300000000000000

    dbg!(*MINER_PRIVATE_KEY);
    dbg!(*MINER_ADDRESS);
    // geth
    //let rpc_host = "127.0.0.1:8545";
    //let rpc_url = "http://localhost:8545";
    // avalanchego
    //let rpc_host = "127.0.0.1:8545";
    let rpc_url = ETH_NODE;
    // go-opera (Fantom)
    //let rpc_host = "127.0.0.1:18545";
    //let rpc_url = "http://localhost:18545";
    // wait for the server to be ready
    /*for _ in 0..120 {
        if TcpStream::connect(rpc_host).await.is_ok() {
            break
        }
        sleep(Duration::from_millis(500)).await
    }
    let rpc = web30::jsonrpc::client::HttpClient::new(rpc_url);

    let methods = [
        // commented out are mentioned in `Web30` but are not used in the bridge
        //"accounts",
        //"chainId",
        //"newFilter",
        //"getLogs",
        "getTransactionCount",
        "gasPrice",
        "estimateGas",
        "getBalance",
        "syncing",
        //"sendTransaction",
        "sendRawTransaction",
        //"call",
        //"blockNumber",
    ];
    for eth_method in methods.into_iter().map(|s| "eth_".to_owned() + s) {
        let res: Result<web30::types::SyncingStatus, Web3Error> = rpc
            .request_method(&eth_method, Vec::<String>::new(), Duration::from_secs(10))
            .await;
        println!("{} => {:?}", eth_method, res);
    }

    let res: Result<web30::types::SyncingStatus, Web3Error> = rpc
        .request_method("eth_syncing", Vec::<String>::new(), Duration::from_secs(10))
        .await;
    dbg!(res);*/

    //let web3 = Web3::new(rpc_url, Duration::from_secs(60));
    // web3.wait_for_next_block(Duration::from_secs(300))
    //     .await
    //     .unwrap();

    // if `should_deploy_contracts()` this needs to be running beforehand,
    // because some chains have really strong quiescence
    // tokio::spawn(async move {
    //     use std::str::FromStr;
    //     // we need a duplicate `send_eth_bulk` that uses a different
    //     // private key and does not wait on transactions, otherwise we
    //     // conflict with the main runner's nonces and calculations
    //     async fn send_eth_bulk2(amount: Uint256, destinations: &[EthAddress],
    // web3: &Web3) {         let private_key: EthPrivateKey =
    //
    // "0x8075991ce870b93a8870eca0c0f91913d12f47948ca0fd25b49c6fa7cdbeee8b"
    //                 .to_owned()
    //                 .parse()
    //                 .unwrap();
    //         let pub_key: EthAddress = private_key.to_address();
    //         let net_version = web3.net_version().await.unwrap();
    //         let mut nonce =
    // web3.eth_get_transaction_count(pub_key).await.unwrap();         let mut
    // transactions = Vec::new();         let gas_price: Uint256 =
    // web3.eth_gas_price().await.unwrap();         let double =
    // gas_price.checked_mul(u256!(2)).unwrap();         for address in
    // destinations {             let t = Transaction {
    //                 to: *address,
    //                 nonce,
    //                 gas_price: double,
    //                 gas_limit: TEST_GAS_LIMIT,
    //                 value: amount,
    //                 data: Vec::new(),
    //                 signature: None,
    //             };
    //             let t = t.sign(&private_key, Some(net_version));
    //             transactions.push(t);
    //             nonce = nonce.checked_add(u256!(1)).unwrap();
    //         }
    //         for tx in transactions {
    //             web3.eth_send_raw_transaction(tx.to_bytes().unwrap())
    //                 .await
    //                 .unwrap();
    //         }
    //     }

    //     // repeatedly send to unrelated addresses
    //     let web3 = Web3::new(ETH_NODE, Duration::from_secs(30));
    //     for i in 0u64.. {
    //         send_eth_bulk2(
    //             u256!(1),
    //             // some chain had a problem with identical transactions being
    // made, alternate             &if (i & 1) == 0 {
    //
    // [EthAddress::from_str("0x798d4Ba9baf0064Ec19eB4F0a1a45785ae9D6DFc").unwrap()]
    //             } else {
    //
    // [EthAddress::from_str("0xFf64d3F6efE2317EE2807d223a0Bdc4c0c49dfDB").unwrap()]
    //             },
    //             &web3,
    //         )
    //         .await;
    //         tokio::time::sleep(Duration::from_secs(4)).await;
    //     }
    // });

    // starting address amount
    /*dbg!(
        web3.eth_get_balance(
            EthAddress::from_str("0xBf660843528035a5A4921534E156a27e64B231fE").unwrap()
        )
        .await
    );

    let (_private_keys, public_keys) = random_keys(1000);
    let send_amount = u256!(1);
    send_eth_bulk(send_amount, &public_keys, &web3).await;
    // note: this may take a while for the initial DAG to generate, this isn't as
    // noticeable in the bridge because of other startup things happening in
    // parallel
    web3.wait_for_next_block(Duration::from_secs(300))
        .await
        .unwrap();
    for (i, key) in public_keys.iter().enumerate().rev() {
        if web3.eth_get_balance(*key).await.unwrap() != send_amount {
            dbg!();
            // wait for an extra 30 seconds for the block stimulator to cause more blocks,
            // show that the transaction totally failed and the bug is not just with
            // unerrored txids being returned
            sleep(Duration::from_secs(30)).await;
            dbg!(web3.eth_get_balance(*key).await.unwrap(), send_amount);
            println!(
                "transaction did not actually happen for key {} ({})",
                i, key
            );
            break
        }
    }

    let mut tot_failed = 0;
    for key in &public_keys {
        if web3.eth_get_balance(*key).await.unwrap() != send_amount {
            tot_failed += 1;
        }
    }

    println!("{} txns failed", tot_failed);*/

    /*dbg!(
        web3.eth_get_balance(
            EthAddress::from_str("0xBf660843528035a5A4921534E156a27e64B231fE").unwrap()
        )
        .await
    );
    dbg!(
        web3.eth_get_balance(
            EthAddress::from_str("0xb3d82b1367d362de99ab59a658165aff520cbd4d").unwrap()
        )
        .await
    );
    dbg!("sending to eth");
    send_eth_bulk(
        u256!(1337),
        &[EthAddress::from_str("0xb3d82b1367d362de99ab59a658165aff520cbd4d").unwrap()],
        &web3,
    )
    .await;
    dbg!("done sending to eth");
    web3.wait_for_next_block(Duration::from_secs(200))
        .await
        .unwrap();
    dbg!("done waiting for next block");
    dbg!(
        web3.eth_get_balance(
            EthAddress::from_str("0xb3d82b1367d362de99ab59a658165aff520cbd4d").unwrap()
        )
        .await
    );*/

    // test contract deploy
    let root = "/rust_container_runner/docker_assets/solidity/";
    //let root = "/home/aaron/rust_container_runner/docker_assets/solidity/";
    let sol_location = root.to_owned() + "src/gravity.sol";
    let contracts_root = PathBuf::from(root);
    let contract_path = ProjectPathsConfig::builder().build_with_root(contracts_root);
    let project = Project::builder()
        .paths(contract_path)
        .set_auto_detect(true)
        .no_artifacts()
        .build()
        .unwrap();
    dbg!();
    // may be downloading a binary, be sure to run with `--release`
    let output = project.compile().unwrap();
    dbg!();
    if output.has_compiler_errors() {
        println!("compilation failed with:\n{:?}", output.output().errors);
        panic!();
    }
    let artifact = output
        .compiled_artifacts()
        .0
        .clone()
        .remove(&sol_location)
        .unwrap()
        .remove("gravity")
        .unwrap()[0]
        .clone()
        .artifact;
    let abi = artifact.abi.as_ref().unwrap().clone();
    let bytecode = artifact.bytecode.as_ref().unwrap().clone();

    let provider =
        ethers::providers::Provider::<ethers::providers::Http>::try_from(ETH_NODE).unwrap();
    // no 0x prefix
    let wallet: LocalWallet = WALLET.to_owned().parse().unwrap();
    let wallet = ethers::signers::Signer::with_chain_id(wallet, CHAIN_ID);
    let client = SignerMiddleware::new(provider.clone(), wallet).into();
    let factory = ContractFactory::new(
        abi.clone().into(),
        bytecode.object.into_bytes().unwrap(),
        client,
    );
    let constructor_args = ();
    let deployer = factory.deploy(constructor_args).unwrap();
    let deployed_contract = deployer.clone().legacy().send().await.unwrap();

    let gravity_address: EthAddress = deployed_contract.address().0.into();
    //dbg!(&gravity_address);
    dbg!(&gravity_address);
    // let gravity_address = "0x0412C7c846bb6b7DC462CF6B453f76D8440b2609"
    //     .parse()
    //     .unwrap();

    /*
        {"id":18,"jsonrpc":"2.0","method":"eth_sendRawTransaction","params":["0xf8a8018495905cc382b5b9940412c7c846bb6b7dc462cf6b453f76d8440b260980b84453de0c530000000000000000000000000000000000000000000000000000000000000000000000000000000000000000bf660843528035a5a4921534e156a27e64b231fe42a0e5621e7fade81c2582f1e42519c38bc30323f4dea37a6b2661cbb0f41907223da05f01870860902fc48c03a2f59b7cdaa2c2fa97d152f7f5764d84ea49e4a05a5c"]}

        // 0x0412C7c846bb6b7DC462CF6B453f76D8440b2609
    Response { id: Number(18), jsonrpc: "2.0", data: Success { result: 58510516575086095322022559644036446469990870932504118152198894874437914036255 } }
    {"id":19,"jsonrpc":"2.0","method":"eth_syncing","params":[]}
    Response { id: Number(19), jsonrpc: "2.0", data: Success { result: NotSyncing(false) } }
    {"id":20,"jsonrpc":"2.0","method":"eth_getTransactionByHash","params":["0x815bc75f9a21b17da8d6d6984ed7c7a6a8ada33e36e5ec2f42c2829cfac9881f"]}
         */

    /*
      function submitBatch(
        uint256 _batchNonce,
        address _tokenContract
    ) public {
        state_lastEventNonce = state_lastEventNonce + 1;
        emit TransactionBatchExecutedEvent(_batchNonce, _tokenContract, state_lastEventNonce);
    }
     */

     pub const TRANSACTION_BATCH_EXECUTED_EVENT_SIG: &str =
     "TransactionBatchExecutedEvent(uint256,address,uint256)";
 
 pub const SENT_TO_COSMOS_EVENT_SIG: &str =
     "SendToCosmosEvent(address,address,string,uint256,uint256)";
 
 pub const ERC20_DEPLOYED_EVENT_SIG: &str =
     "ERC20DeployedEvent(string,address,string,string,uint8,uint256)";
 
 pub const LOGIC_CALL_EVENT_SIG: &str = "LogicCallEvent(bytes32,uint256,bytes,uint256)";
 
 pub const VALSET_UPDATED_EVENT_SIG: &str =
     "ValsetUpdatedEvent(uint256,uint256,uint256,address,address[],uint256[])";
 

    let web3 = Web3::new(rpc_url, Duration::from_secs(60));

    /*
    INFO [12-16|23:03:37.130] Submitted contract creation              hash=0xb8a6afcbd48f723974d1977a7dc1d6ca489b12f4246d603a8ba7ef9f8b43465a from=0xBf660843528035a5A4921534E156a27e64B231fE nonce=0 contract=0x0412C7c846bb6b7DC462CF6B453f76D8440b2609 value=0
     */
    let tx_hash = web3
        .send_transaction(
            gravity_address,
            clarity::abi::encode_call("submitBatch(uint256,address)", &[
                Token::Uint(u256!(1)),
                Token::Address(*MINER_ADDRESS),
            ])
            .unwrap(),
            u256!(0),
            *MINER_ADDRESS,
            &MINER_PRIVATE_KEY,
            vec![
                SendTxOption::GasPriceMultiplier(2.0),
                SendTxOption::GasLimit(u256!(200_000)),
            ],
        )
        .await
        .unwrap();

    web3.wait_for_transaction(tx_hash, Duration::from_secs(30), None)
        .await
        .unwrap();

    /*
    {"id":3,"jsonrpc":"2.0","method":"eth_getLogs","params":[{"fromBlock":"0x0","toBlock":"0x2cd","address":["0x09260B44D8763F456BCF62c47D6BbB46C8C71204"],"topics":[["0x02c7e81975f8edb86e2a0c038b7b86a49c744236abf0f6177ff5afc6986ab708"]]}]}

    curl --header "content-type: application/json" --data '{"method":"eth_blockNumber","params":[],"id":1,"jsonrpc":"2.0"}' http://localhost:8545

    curl --header "content-type: application/json" --data '{"method":"eth_getLogs","params":[{"fromBlock":"0x0","toBlock":"0x2cd","address":["0x09260B44D8763F456BCF62c47D6BbB46C8C71204"],"topics":[["0x02c7e81975f8edb86e2a0c038b7b86a49c744236abf0f6177ff5afc6986ab708"]]}],"id":1,"jsonrpc":"2.0"}' http://localhost:8545

    {"id":5,"jsonrpc":"2.0","method":"eth_getLogs","params":[{"fromBlock":"0x0","toBlock":"0x1aa","address":["0xD7600ae27C99988A6CD360234062b540F88ECA43"],"topics":[["0x82fe3a4fa49c6382d0c085746698ddbbafe6c2bf61285b19410644b5b26287c7"]]}]}

    curl --header "content-type: application/json" --data '{"method":"eth_getLogs","params":[{"fromBlock":"0x0","toBlock":"0x2cd","address":["0x0412C7c846bb6b7DC462CF6B453f76D8440b2609"]}],"id":1,"jsonrpc":"2.0"}' http://localhost:9090/solana



# curl --header "content-type: application/json" --data '{"method":"eth_getLogs","params":[{"fromBlock":"0x0","toBlock":"0x2cd","address":["0x0412C7c846bb6b7DC462CF6B453f76D8440b2609"]}],"id":1,"jsonrpc":"2.0"}' http://localhost:9090/solana
{"jsonrpc": "2.0", "id": 1, "result": [{"blockNumber": "0x104", "transactionIndex": "0x0", "transactionLogIndex": "0x0", "logIndex": "0x0", "address": "0x0412c7c846bb6b7dc462cf6b453f76d8440b2609", "data": "0x0000000000000000000000000000000000000000000000000000000000000001", "transactionHash": "0x0469c85ce2c1288bab35eed1846e0857542a33d4c0421c175b7adc5f1052ffc2", "topics": ["0x02c7e81975f8edb86e2a0c038b7b86a49c744236abf0f6177ff5afc6986ab708", "0x0000000000000000000000000000000000000000000000000000000000000001", "0x000000000000000000000000bf660843528035a5a4921534e156a27e64b231fe"], "blockHash": "0x271a1e92bb3a41a310acb1d4e53a7a913f7f3588cf224f507d8f1e1905aa24ea"}]}

# curl --header "content-type: application/json" --data '{"method":"eth_getLogs","params":[{"fromBlock":"0x0","toBlock":"0xffff","address":["0x0412C7c846bb6b7DC462CF6B453f76D8440b2609"],"topics":[["0x02c7e81975f8edb86e2a0c038b7b86a49c744236abf0f6177ff5afc6986ab708"]]}],"id":1,"jsonrpc":"2.0"}' http://localhost:9090/solana

# curl --header "content-type: application/json" --data '{"method":"eth_getLogs","params":[{"fromBlock":"0x0","toBlock":"0xffff","address":["0x0412C7c846bb6b7DC462CF6B453f76D8440b2609"],"topics":[["0x0000000000000000000000000000000000000000000000000000000000000001"]]}],"id":1,"jsonrpc":"2.0"}' http://localhost:9090/solana

    */

    let mut file0 = std::fs::OpenOptions::new().truncate(true).write(true).create(true).open("/rust_container_runner/docker_assets/requests.txt").unwrap();
    let mut file1 = std::fs::OpenOptions::new().truncate(true).write(true).create(true).open("/rust_container_runner/docker_assets/responses.txt").unwrap();
    use std::fmt::Write;
    let requests = web30::JSON_RPC_REQUESTS.lock().unwrap();
    let requests = requests.iter().fold(String::new(), |mut acc, (c, s)| {writeln!(acc, "{}\n{}", c, s).unwrap(); acc});
    std::io::Write::write_all(&mut file0, requests.as_bytes()).unwrap();
    drop(file0);
    let responses = web30::JSON_RPC_RESPONSES.lock().unwrap();
    let responses = responses.iter().fold(String::new(), |mut acc, (c, s)| {writeln!(acc, "{}\n{}", c, s).unwrap(); acc});
    std::io::Write::write_all(&mut file1, responses.as_bytes()).unwrap();
    drop(file1);

    dbg!();
    let _logs = web3
        .check_for_events(u256!(0), None, vec![gravity_address], vec![
            TRANSACTION_BATCH_EXECUTED_EVENT_SIG,
        ])
        .await
        .unwrap();
    let _logs = web3
    .check_for_events(u256!(0), None, vec![gravity_address], vec![
        SENT_TO_COSMOS_EVENT_SIG,
    ])
    .await
    .unwrap();
    let _logs = web3
    .check_for_events(u256!(0), None, vec![gravity_address], vec![
        ERC20_DEPLOYED_EVENT_SIG,
    ])
    .await
    .unwrap();
    let _logs = web3
    .check_for_events(u256!(0), None, vec![gravity_address], vec![
        LOGIC_CALL_EVENT_SIG,
    ])
    .await
    .unwrap();
    let _logs = web3
    .check_for_events(u256!(0), None, vec![gravity_address], vec![
        VALSET_UPDATED_EVENT_SIG,
    ])
    .await
    .unwrap();
}

async fn wait_for_txids(txids: Vec<Result<Uint256, Web3Error>>, web3: &Web3) {
    let mut wait_for_txid = Vec::new();
    for txid in txids {
        if let Ok(txid) = txid {
            let wait = web3.wait_for_transaction(txid, Duration::from_secs(30), None);
            wait_for_txid.push(wait);
        } else {
            println!("tx failed with: {:?}", txid);
        }
    }
    dbg!("waiting for txn");
    join_all(wait_for_txid).await;
    dbg!("done waiting for txn");
}

pub async fn send_eth_bulk(amount: Uint256, destinations: &[EthAddress], web3: &Web3) {
    let net_version = web3.net_version().await.unwrap();
    let mut nonce = web3
        .eth_get_transaction_count(*MINER_ADDRESS)
        .await
        .unwrap();
    let mut transactions = Vec::new();
    let gas_price: Uint256 = web3.eth_gas_price().await.unwrap();
    for address in destinations {
        let t = Transaction {
            to: *address,
            nonce,
            gas_price: gas_price.checked_mul(u256!(2)).unwrap(),
            gas_limit: u256!(2405040),
            value: amount,
            data: Vec::new(),
            signature: None,
        };
        let t = t.sign(&MINER_PRIVATE_KEY, Some(net_version));
        transactions.push(t);
        nonce = nonce.checked_add(u256!(1)).unwrap();
    }
    let mut sends = Vec::new();
    for tx in transactions {
        sends.push(web3.eth_send_raw_transaction(tx.to_bytes().unwrap()));
    }
    let txids = join_all(sends).await;
    wait_for_txids(txids, web3).await;
}

pub fn random_keys(len: usize) -> (Vec<EthPrivateKey>, Vec<EthAddress>) {
    let mut res = (vec![], vec![]);
    for _ in 0..len {
        let mut rng = rand::thread_rng();
        let secret: [u8; 32] = rand::Rng::gen(&mut rng);
        // the starting location of the funds
        let eth_key = EthPrivateKey::from_slice(&secret).unwrap();
        let eth_address = eth_key.to_address();
        res.0.push(eth_key);
        res.1.push(eth_address);
    }
    res
}
