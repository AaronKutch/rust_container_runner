use std::time::Duration;

use tokio::{net::TcpStream, time::sleep};
use web30::{jsonrpc::client::HttpClient};

#[tokio::main]
pub async fn main() {
    let rpc_host = "127.0.0.1:18545";
    let rpc_url = "http://localhost:18545";
    //let rpc_url = "http://localhost:9650/ext/bc/C/rpc";
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
        let res: Result<String, _> = rpc
            .request_method(&eth_method, Vec::<String>::new(), Duration::from_secs(10))
            .await;
        println!("{:?}", res);
    }
    /*let res: SyncingStatus = rpc
        .request_method("eth_syncing", Vec::<String>::new(), Duration::from_secs(10))
        .await
        .unwrap();
    dbg!(res);*/
    //let web3 = Web3::new(rpc_url, Duration::from_secs(60));
    // calls "eth_syncing" with empty parameters
    //dbg!(web3.eth_syncing().await.unwrap());
}
