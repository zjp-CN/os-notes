use executor::TimerFuture;
use io_uring::{opcode, types};
use std::{
    fs::File as StdFile,
    future::poll_fn,
    io::{self, Result},
    os::fd::AsRawFd,
    task::Poll,
    time::Duration,
};

mod driver;
mod executor;

fn main() {
    const PATH: &str = "Cargo.toml";

    executor::Executor::block_on(|spawner| async move {
        spawner.spawn(TimerFuture::new(1.0));
        spawner.spawn(Timeout::new(Duration::from_millis(500)));

        spawner.spawn(async {
            let mut buf = vec![0; 1024];
            let read_len = read_at("Cargo.toml", 0, &mut buf).await.unwrap();
            let content = std::str::from_utf8(&buf[..read_len]).unwrap();
            println!("buf 1024:\n{content}");
        });

        spawner.spawn(async {
            println!(
                "async read_to_string:\n{}",
                read_to_string(PATH).await.unwrap()
            );
        });
    });
}

/// Bad practice with borrowed buffer!!! (Though it seems to work.)
fn read_at(path: &str, offset: u64, buf: &mut [u8]) -> impl Future<Output = Result<usize>> {
    struct File {
        file: Option<StdFile>,
        index: usize,
        buffer_len: usize,
    }

    let mut file = {
        let file = StdFile::open(path).unwrap();
        let ptr = buf.as_mut_ptr();
        let len = buf.len();

        let fd = types::Fd(file.as_raw_fd());
        let sqe = opcode::Read::new(fd, ptr, len as _).offset(offset).build();
        File {
            file: Some(file),
            index: driver::submit(sqe),
            buffer_len: len,
        }
    };

    poll_fn(move |cx| {
        let Some(cqe) = driver::poll(file.index, cx.waker()) else {
            return Poll::Pending;
        };

        driver::remove(file.index);
        drop(file.file.take().expect("File has been closed."));

        let res = cqe.result();
        let read_len = if res < 0 {
            return Poll::Ready(Err(io::Error::from_raw_os_error(-res)));
        } else {
            res as usize
        };

        assert!(
            read_len <= file.buffer_len,
            "Bytes filled exceed the buffer length."
        );

        Poll::Ready(Ok(read_len))
    })
}

/// Read whole content from a file via filling the buffer block by block.
pub async fn read_to_string(path: &str) -> Result<String> {
    const BLOCK: usize = 24;
    let mut buf = vec![0; BLOCK];
    let mut pos = 0;

    loop {
        let read_len = read_at(path, pos as u64, &mut buf[pos..pos + BLOCK]).await?;
        // println!("pos = {pos}, read_len = {read_len}");
        if read_len == 0 {
            // EOF
            break;
        }

        // move the cursor and allocate a block
        pos += read_len;
        buf.resize(pos + BLOCK, 0);
    }

    // println!("[read_to_string] ret");
    Ok(String::from_utf8(buf).expect("Content contains non UTF8 bytes."))
}

#[test]
fn test_probe() {
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

#[allow(dead_code)]
struct Timeout {
    time_spec: Box<types::Timespec>,
    duration: Duration,
    index: usize,
}

impl Timeout {
    fn new(duration: Duration) -> Self {
        // NOTE: *const Timespec must be valid until cqe is got.
        // So simply put the value on the heap to make it work.
        let time_spec = Box::new(
            types::Timespec::new()
                .sec(duration.as_secs())
                .nsec(duration.subsec_nanos()),
        );
        let sqe = opcode::Timeout::new(&*time_spec).count(0).build();
        let index = driver::submit(sqe);
        Timeout {
            time_spec,
            duration,
            index,
        }
    }
}

impl Future for Timeout {
    type Output = ();

    fn poll(self: std::pin::Pin<&mut Self>, cx: &mut std::task::Context<'_>) -> Poll<Self::Output> {
        let dur = self.duration;
        println!("Poll Timeout: {dur:?}");
        let Some(cqe) = driver::poll(self.index, cx.waker()) else {
            println!("Pending Timeout: {dur:?}");
            return Poll::Pending;
        };
        let res = cqe.result();
        if res > 0 {
            return Poll::Pending;
        }

        driver::remove(self.index);
        println!(
            "Ready Timeout: {dur:?}\t {:?}",
            std::io::Error::from_raw_os_error(-cqe.result())
        );
        Poll::Ready(())
    }
}

#[test]
fn test_timeout() {
    executor::Executor::block_on(|spawner| async move {
        spawner.spawn(Timeout::new(Duration::from_secs(5)));
        spawner.spawn(Timeout::new(Duration::from_secs(3)));
        spawner.spawn(Timeout::new(Duration::from_secs(1)));
        spawner.spawn(Timeout::new(Duration::from_millis(100)));
    });
}
