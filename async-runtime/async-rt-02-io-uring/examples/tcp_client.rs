use std::io::prelude::*;
fn main() -> std::io::Result<()> {
    let mut stream = std::net::TcpStream::connect("127.0.0.1:3456")?;

    dbg!(stream.write(&[1, 2, 3])?);

    for x in 5..10 {
        std::thread::sleep(std::time::Duration::from_secs(1));
        dbg!(stream.write(&[x])?);
    }

    let mut var_name = vec![0; 10];
    dbg!(stream.read(&mut var_name)?, &var_name);

    drop(stream);
    std::thread::sleep(std::time::Duration::from_secs(3));

    Ok(())
}
