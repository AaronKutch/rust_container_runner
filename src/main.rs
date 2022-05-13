#![allow(unused_must_use)]
use std::{env, str::FromStr, time::Duration};

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
        "0x56289e99c94b6912bfc12adc093c9b51124f0dc54ac7a766b2bc5ccf558d8027".to_owned()
            ).parse()
            .unwrap();
    static ref MINER_ADDRESS: EthAddress = MINER_PRIVATE_KEY.to_address();
}
pub const HIGH_GAS_PRICE: Uint256 = u256!(1_000_000_000);

#[tokio::main]
pub async fn main() {
    dbg!(*MINER_PRIVATE_KEY);
    dbg!(*MINER_ADDRESS);
    // geth
    //let rpc_host = "127.0.0.1:8545";
    //let rpc_url = "http://localhost:8545";
    // avalanchego
    let rpc_host = "127.0.0.1:9650";
    let rpc_url = "http://localhost:9650/ext/bc/C/rpc";
    // go-opera (Fantom)
    //let rpc_host = "127.0.0.1:18545";
    //let rpc_url = "http://localhost:18545";
    // wait for the server to be ready
    for _ in 0..120 {
        if TcpStream::connect(rpc_host).await.is_ok() {
            break
        }
        sleep(Duration::from_millis(500)).await
    }
    let rpc = HttpClient::new(rpc_url);

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
        let res: Result<SyncingStatus, Web3Error> = rpc
            .request_method(&eth_method, Vec::<String>::new(), Duration::from_secs(10))
            .await;
        println!("{} => {:?}", eth_method, res);
    }

    let res: Result<SyncingStatus, Web3Error> = rpc
        .request_method("eth_syncing", Vec::<String>::new(), Duration::from_secs(10))
        .await;
    dbg!(res);

    let web3 = Web3::new(rpc_url, Duration::from_secs(60));

    sleep(Duration::from_secs(5)).await;
    //web3.wait_for_next_block(Duration::from_secs(120))
    //    .await
    //    .unwrap();

    //0xb1bab011e03a9862664706fc3bbaa1b16651528e5f0e7fbfcbfdd8be302a13e7
    //0xBf660843528035a5A4921534E156a27e64B231fE
    //0x163F5F0F9A621D72FEDD85FFCA3D08D131AB4E812181E0D30FFD1C885D20AAC7
    //0x239fA7623354eC26520dE878B52f13Fe84b06971
    dbg!(
        web3.eth_get_balance(
            EthAddress::from_str("0xBf660843528035a5A4921534E156a27e64B231fE").unwrap()
        )
        .await
    );
    dbg!(
        web3.eth_get_balance(
            EthAddress::from_str("0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC").unwrap()
        )
        .await
    );
    send_eth_bulk(
        u256!(900000000000000000000000000),
        &[EthAddress::from_str("0xBf660843528035a5A4921534E156a27e64B231fE").unwrap()],
        &web3,
    )
    .await;
    dbg!(
        web3.eth_get_balance(
            EthAddress::from_str("0xBf660843528035a5A4921534E156a27e64B231fE").unwrap()
        )
        .await
    );
    dbg!(
        web3.eth_get_balance(
            EthAddress::from_str("0x8db97C7cEcE249c2b98bDC0226Cc4C2A57BF52FC").unwrap()
        )
        .await
    );
}

async fn wait_for_txids(txids: Vec<Result<Uint256, Web3Error>>, web3: &Web3) {
    let mut wait_for_txid = Vec::new();
    for txid in txids {
        let wait = web3.wait_for_transaction(txid.unwrap(), Duration::from_secs(30), None);
        wait_for_txid.push(wait);
    }
    join_all(wait_for_txid).await;
}

pub async fn send_eth_bulk(amount: Uint256, destinations: &[EthAddress], web3: &Web3) {
    let net_version = web3.net_version().await.unwrap();
    let mut nonce = web3
        .eth_get_transaction_count(*MINER_ADDRESS)
        .await
        .unwrap();
    let mut transactions = Vec::new();
    for address in destinations {
        let t = Transaction {
            to: *address,
            nonce,
            gas_price: HIGH_GAS_PRICE,
            gas_limit: u256!(24000),
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
