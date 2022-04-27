use std::time::Duration;

use tokio::{time::sleep, net::TcpStream};
use web30::client::Web3;

#[tokio::main]
pub async fn main() {
    let rpc_addr = "http://localhost:9650/ext/bc/C/rpc";
    // wait for the server to be ready for 60 seconds
    for _ in 0..120 {
        if TcpStream::connect(rpc_addr).await.is_ok() {
            break
        }
        sleep(Duration::from_millis(500)).await
    }
    let web3 = Web3::new(rpc_addr, Duration::from_secs(60));
    // calls "eth_syncing" with empty parameters
    dbg!(web3.eth_syncing().await.unwrap());
}
