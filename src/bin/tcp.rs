// A basic TCP listener for the sole purpose of debugging connectivity issues

use std::net::TcpListener;

fn main() -> std::io::Result<()> {
    let listener = TcpListener::bind("0.0.0.0:8899")?;

    for stream in listener.incoming() {
        println!("connecting\n");
        dbg!(stream.unwrap());
    }
    Ok(())
}
