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
    executor::Executor::block_on(|spawner| async move {
        spawner.spawn(TimerFuture::new(1.0));

        let buf = File::read("Cargo.toml").await.unwrap();
        let content = String::from_utf8(buf).unwrap();
        println!("{content}");
    });

    Ok(())
}

struct Op {
    /// position in slab
    index: usize,
    /// buffer that is passed to io_uring and taken away if completed
    buffer: Option<Vec<u8>>,
}

struct File {
    file: Option<StdFile>,
    op: Op,
}

impl File {
    /// Read from pos 0 with a fixed-capacity buffer.
    fn read(path: &str) -> impl Future<Output = Result<Vec<u8>>> {
        let mut file = {
            let file = OpenOptions::new()
                .read(true)
                .write(true)
                .open(path)
                .unwrap();
            let offset = 0;
            let mut buffer = Vec::with_capacity(1024);
            let ptr = dbg!(buffer.as_mut_ptr());
            let len = buffer.capacity();

            let sqe = opcode::Read::new(types::Fd(dbg!(file.as_raw_fd())), ptr, len as _)
                .offset(offset as _)
                .build();
            let index = driver::submit(sqe);

            File {
                file: Some(file),
                op: Op {
                    index,
                    buffer: Some(buffer),
                },
            }
        };

        poll_fn(move |cx| {
            let cqe = driver::poll(file.op.index, cx.waker());
            if let Some(cqe) = cqe {
                let res = cqe.result();

                let len = if res < 0 {
                    return Poll::Ready(Err(io::Error::from_raw_os_error(-res)));
                } else {
                    res as usize
                };

                let mut buffer = file.op.buffer.take().unwrap();
                unsafe { buffer.set_len(len) };

                drop(file.file.take().unwrap());
                Poll::Ready(Ok(buffer))
            } else {
                Poll::Pending
            }
        })
    }
}
