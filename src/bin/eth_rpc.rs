#![allow(unused_must_use)]
use std::{env, iter, str::FromStr, time::Duration};

use clarity::{
    address::Address as EthAddress, u256, PrivateKey as EthPrivateKey, Transaction, Uint256,
};
use futures::future::join_all;
use lazy_static::lazy_static;
use tokio::{net::TcpStream, time::sleep};
use web30::{
    client::Web3,
    jsonrpc::{client::HttpClient, error::Web3Error},
    types::SyncingStatus,
};

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
pub const HIGH_GAS_PRICE: Uint256 = u256!(30000000000);

#[tokio::main]
pub async fn main() {
    dbg!(*MINER_PRIVATE_KEY);
    dbg!(*MINER_ADDRESS);
    // geth, bor, and go-opera
    //let rpc_host = "127.0.0.1:8545";
    //let rpc_url = "http://localhost:8545";
    // avalanchego
    //let rpc_host = "127.0.0.1:8545";
    //let rpc_url = "http://localhost:8545/ext/bc/C/rpc";
    //let rpc_host = "127.0.0.1:8899";
    // neon
    let rpc_url = "http://proxy:9090/solana";
    let rpc_host = "http://proxy:9090";

    // wait for the server to be ready
    /*for _ in 0..40 {
        if TcpStream::connect(rpc_host).await.is_ok() {
            break
        }
        sleep(Duration::from_millis(500)).await
    }
    let rpc = HttpClient::new(rpc_url);

    let calls = [
        // commented out are mentioned in `Web30` but are not used in the bridge
        //"eth_accounts",
        //"eth_chainId",
        //"eth_newFilter",
        //"eth_getLogs",
        vec![
            "eth_getTransactionCount".to_owned(),
            EthAddress::default().to_string(),
            "latest".to_string(),
        ],
        vec!["eth_gasPrice".to_string()],
        vec![
            "eth_estimateGas".to_string(),
            EthAddress::default().to_string(),
        ],
        vec![
            "eth_getBalance".to_string(),
            EthAddress::default().to_string(),
            "latest".to_string(),
        ],
        vec!["eth_syncing".to_string()],
        //"eth_sendTransaction",
        vec!["eth_sendRawTransaction".to_string(), "0x0".to_string()],
        //"eth_call",
        //"eth_blockNumber",
    ];
    for call in calls.into_iter() {
        let res: Result<String, Web3Error> = rpc
            .request_method(&call[0], call[1..].to_owned(), Duration::from_secs(10))
            .await;
        println!("{} => {:?}", &call[0], res);
    }

    let res: Result<SyncingStatus, Web3Error> = rpc
        .request_method("eth_syncing", Vec::<String>::new(), Duration::from_secs(10))
        .await;
    dbg!(res);*/

    let web3 = Web3::new(rpc_url, Duration::from_secs(60));

    dbg!();
    dbg!(web3.eth_syncing().await);
    dbg!();
    dbg!(web3.eth_synced_block_number().await);
    dbg!();

    // just the same address twice for simplicity
    let addresses: Vec<_> =
        iter::repeat(EthAddress::from_str("0xb3d82b1367d362de99ab59a658165aff520cbd4d").unwrap())
            .take(2)
            .collect();
    dbg!("sending serially");
    send_eth_bulk_serially(u256!(1), &addresses, &web3).await;
    dbg!("sending in parallel");
    send_eth_bulk_parallel(u256!(1), &addresses, &web3).await;
}

async fn wait_for_txids(txids: Vec<Result<Uint256, Web3Error>>, web3: &Web3) {
    let mut wait_for_txid = Vec::new();
    for txid in txids {
        let wait = web3.wait_for_transaction(txid.unwrap(), Duration::from_secs(30), None);
        wait_for_txid.push(wait);
    }
    dbg!("waiting for txn");
    join_all(wait_for_txid).await;
    dbg!("done waiting for txn");
}

pub async fn send_eth_bulk_parallel(amount: Uint256, destinations: &[EthAddress], web3: &Web3) {
    let net_version = web3.net_version().await.unwrap();
    let mut nonce = web3
        .eth_get_transaction_count(*MINER_ADDRESS)
        .await
        .unwrap();
    let mut transactions = Vec::new();
    for address in destinations {
        dbg!(nonce);
        let t = Transaction {
            to: *address,
            nonce,
            gas_price: HIGH_GAS_PRICE,
            gas_limit: u256!(2000000),
            value: amount,
            data: Vec::new(),
            signature: None,
        };
        let t = t.sign(&*MINER_PRIVATE_KEY, Some(net_version));
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

pub async fn send_eth_bulk_serially(amount: Uint256, destinations: &[EthAddress], web3: &Web3) {
    let net_version = web3.net_version().await.unwrap();
    let gas_price: Uint256 = web3.eth_gas_price().await.unwrap();
    for address in destinations {
        let mut transactions = Vec::new();
        let nonce = web3
            .eth_get_transaction_count(*MINER_ADDRESS)
            .await
            .unwrap();
        dbg!(nonce);
        let t = Transaction {
            to: *address,
            nonce,
            gas_price: gas_price.checked_mul(u256!(2)).unwrap(),
            gas_limit: u256!(2000000),
            value: amount,
            data: Vec::new(),
            signature: None,
        };
        let t = t.sign(&*MINER_PRIVATE_KEY, Some(net_version));
        transactions.push(t);
        //nonce = nonce.checked_add(u256!(1)).unwrap();
        let mut sends = Vec::new();
        for tx in transactions {
            sends.push(web3.eth_send_raw_transaction(tx.to_bytes().unwrap()));
        }
        let txids = join_all(sends).await;
        wait_for_txids(txids, web3).await;
    }
}
