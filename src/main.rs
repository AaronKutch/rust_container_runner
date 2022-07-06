#![allow(unused_must_use)]
use std::{env, str::FromStr, time::Duration};

use clarity::{
    address::Address as EthAddress, u256, PrivateKey as EthPrivateKey, Transaction, Uint256,
};
use futures::future::join_all;
use lazy_static::lazy_static;
use tokio::{net::TcpStream, time::sleep};
use web30::{client::Web3, jsonrpc::error::Web3Error};

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
pub const HIGH_GAS_PRICE: Uint256 = u256!(300000000000);

#[tokio::main]
pub async fn main() {
    dbg!(*MINER_PRIVATE_KEY);
    dbg!(*MINER_ADDRESS);
    // geth
    //let rpc_host = "127.0.0.1:8545";
    //let rpc_url = "http://localhost:8545";
    // avalanchego
    let rpc_host = "127.0.0.1:8545";
    let rpc_url = "http://localhost:8545/ext/bc/C/rpc";
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
    //let rpc = HttpClient::new(rpc_url);

    /*let methods = [
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
    dbg!(res);*/

    tokio::spawn(async move {
        use std::str::FromStr;
        // we need a duplicate `send_eth_bulk` that uses a different
        // private key and does not wait on transactions, otherwise we
        // conflict with the main runner's nonces and calculations

        async fn send_eth_bulk2(amount: Uint256, destinations: &[EthAddress], web3: &Web3) {
            let private_key: EthPrivateKey =
                "0x8075991ce870b93a8870eca0c0f91913d12f47948ca0fd25b49c6fa7cdbeee8b"
                    .to_owned()
                    .parse()
                    .unwrap();
            let pub_key: EthAddress = private_key.to_address();
            let net_version = web3.net_version().await.unwrap();
            let mut nonce = web3.eth_get_transaction_count(pub_key).await.unwrap();
            let mut transactions = Vec::new();
            let gas_price: Uint256 = web3.eth_gas_price().await.unwrap();
            dbg!(&gas_price);
            for address in destinations {
                let t = Transaction {
                    to: *address,
                    nonce,
                    gas_price: HIGH_GAS_PRICE,//gas_price.checked_mul(u256!(2)).unwrap(),
                    gas_limit: u256!(24000),
                    value: amount,
                    data: Vec::new(),
                    signature: None,
                };
                let t = t.sign(&private_key, Some(net_version));
                transactions.push(t);
                nonce = nonce.checked_add(u256!(1)).unwrap();
            }
            for tx in transactions {
                let _ = web3.eth_send_raw_transaction(tx.to_bytes().unwrap()).await;
            }
        }

        // repeatedly send single atoms to unrelated address
        let web3 = Web3::new(rpc_url, Duration::from_secs(60));
        loop {
            send_eth_bulk2(
                u256!(1),
                &[EthAddress::from_str("0x798d4Ba9baf0064Ec19eB4F0a1a45785ae9D6DFc").unwrap()],
                &web3,
            )
            .await;
            tokio::time::sleep(Duration::from_secs(1)).await;
        }
    });

    let web3 = Web3::new(rpc_url, Duration::from_secs(60));

    //sleep(Duration::from_secs(5)).await;
    //web3.wait_for_next_block(Duration::from_secs(120))
    //    .await
    //    .unwrap();

    dbg!(
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
        u256!(10000000000000000000000000),
        &[EthAddress::from_str("0xb3d82b1367d362de99ab59a658165aff520cbd4d").unwrap()],
        &web3,
    )
    .await;
    dbg!("done sending to eth");
    web3.wait_for_next_block(Duration::from_secs(120))
        .await
        .unwrap();
    dbg!("done waiting for next block");
    dbg!(
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

pub async fn send_eth_bulk(amount: Uint256, destinations: &[EthAddress], web3: &Web3) {
    let net_version = web3.net_version().await.unwrap();
    let mut nonce = web3
        .eth_get_transaction_count(*MINER_ADDRESS)
        .await
        .unwrap();
    let mut transactions = Vec::new();
    let gas_price: Uint256 = web3.eth_gas_price().await.unwrap();
    dbg!(&gas_price);
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