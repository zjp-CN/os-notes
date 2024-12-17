use executor::TimerFuture;
use io_uring::{opcode, types};
use std::{
    fs::{File as StdFile, OpenOptions},
    future::poll_fn,
    io::{self, Result},
    os::fd::AsRawFd,
    task::Poll,
};

mod driver;
mod executor;

fn main() -> Result<()> {
    const PATH: &str = "Cargo.toml";
    executor::Executor::block_on(|spawner| async move {
        spawner.spawn(TimerFuture::new(1.0));

        spawner.spawn(async {
            let mut buf = vec![0; 1024];
            let read_len = File::read_at("Cargo.toml", 0, &mut buf).await.unwrap();
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

    Ok(())
}

struct Op {
    /// position in slab
    index: usize,
    buffer_len: usize,
}

struct File {
    file: Option<StdFile>,
    op: Op,
}

impl File {
    /// Read from pos 0 with a fixed-capacity buffer.
    fn read_at(path: &str, offset: u64, buf: &mut [u8]) -> impl Future<Output = Result<usize>> {
        let mut file = {
            let file = OpenOptions::new()
                .read(true)
                .write(true)
                .open(path)
                .unwrap();
            let ptr = dbg!(buf.as_mut_ptr());
            let len = buf.len();

            let fd = types::Fd(dbg!(file.as_raw_fd()));
            let sqe = opcode::Read::new(fd, ptr, len as _).offset(offset).build();
            let index = driver::submit(sqe);

            File {
                file: Some(file),
                op: Op {
                    index,
                    buffer_len: len,
                },
            }
        };

        poll_fn(move |cx| {
            if let Some(cqe) = driver::poll(file.op.index, cx.waker()) {
                driver::remove(file.op.index);
                let res = cqe.result();
                let read_len = if res < 0 {
                    return Poll::Ready(Err(io::Error::from_raw_os_error(-res)));
                } else {
                    res as usize
                };

                assert!(
                    read_len <= file.op.buffer_len,
                    "Bytes filled exceed the buffer length."
                );
                drop(file.file.take().expect("File has been closed."));

                Poll::Ready(Ok(read_len))
            } else {
                Poll::Pending
            }
        })
    }
}

/// Read whole content from a file via filling the buffer block by block.
pub async fn read_to_string(path: &str) -> Result<String> {
    const BLOCK: usize = 24;
    let mut buf = vec![0; BLOCK];
    let mut pos = 0;

    loop {
        let read_len = File::read_at(path, pos as u64, &mut buf[pos..pos + BLOCK]).await?;
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
    Ok(String::from_utf8(buf).unwrap())
}
