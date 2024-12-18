use crate::{
    Result,
    async_io::{File, TcpStream},
};
use std::str::from_utf8;

pub async fn test_tcp_fut() -> Result<()> {
    let stream = TcpStream::connect("127.0.0.1:3456".parse().unwrap())?;
    let data: Vec<u8> = (1..10).collect();
    let len = data.len();

    let (res, buf) = stream.write(data.clone()).await;
    assert_eq!(res?, len);
    assert_eq!(buf, data);

    let (res, buf) = stream.read(vec![0; len]).await;
    assert_eq!(res?, len);
    assert_eq!(buf, data);

    Ok(())
}

#[test]
fn test_tcp() {
    crate::executor::Executor::block_on(|_| async { test_tcp_fut().await.unwrap() });
}

pub async fn test_file_read() -> Result<()> {
    let file = File::open("Cargo.toml", |_| {})?;
    let (res, buf) = file.read(vec![0; 24]).await;
    let read_len = dbg!(res?);
    println!("[task 1] read:\n{}", from_utf8(&buf[..read_len])?);
    Ok(())
}

#[test]
fn test_file() {
    crate::executor::Executor::block_on(|spawner| async move {
        spawner.spawn_result(test_file_read());
        test_file_write_and_read().await.unwrap();
    });
}

pub async fn test_file_write_and_read() -> Result<()> {
    const TMP: &str = "tmp.txt";

    let file = File::open(TMP, |opt| _ = opt.write(true).create(true).append(true))?;
    let (res, _) = file.write("Hello world!".as_bytes().to_owned()).await;
    dbg!(res?);

    let (res, buf) = file.read(vec![0; 1024]).await;
    let read_len = dbg!(res?);
    println!("[task 2] read:\n{}", from_utf8(&buf[..read_len])?);

    std::fs::remove_file(TMP)?;
    Ok(())
}

#[test]
fn test_probe() {
    use io_uring::opcode;
    let mut probe = io_uring::Probe::new();

    let ring = io_uring::IoUring::new(1).unwrap();
    if ring.submitter().register_probe(&mut probe).is_err() {
        eprintln!("No probe supported");
    }

    assert!(
        probe.is_supported(opcode::Read::CODE),
        "Read event is not supported in io uring"
    );
    assert!(
        probe.is_supported(opcode::Timeout::CODE),
        "Timeout event is not supported in io uring"
    );
}
