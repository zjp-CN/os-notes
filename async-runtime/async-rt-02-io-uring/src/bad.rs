use crate::driver;
use io_uring::{opcode, types};
use std::{
    fs::File as StdFile,
    future::poll_fn,
    io::{self, Result},
    os::fd::AsRawFd,
    task::Poll,
};

/// Bad practice with borrowed buffer!!! (Though it works.)
pub fn read_at<'buf>(
    path: &str,
    offset: u64,
    buf: &'buf mut [u8],
) -> impl use<'buf> + Future<Output = Result<usize>> {
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
        if read_len == 0 {
            // EOF
            break;
        }

        // move the cursor and allocate a block
        pos += read_len;
        buf.resize(pos + BLOCK, 0);
    }

    Ok(String::from_utf8(buf).expect("Content contains non UTF8 bytes."))
}

#[test]
fn test_bad_read_api() {
    const PATH: &str = "Cargo.toml";
    crate::executor::Executor::block_on(|spawner| async move {
        spawner.spawn_result(async {
            let mut buf = vec![0; 1024];
            let read_len = read_at("Cargo.toml", 0, &mut buf).await?;
            let content = std::str::from_utf8(&buf[..read_len]).unwrap();
            println!("Cargo.toml:\n{content}");
            Ok(())
        });

        spawner.spawn_result(async {
            println!("async read_to_string:\n{}", read_to_string(PATH).await?);
            Ok(())
        });
    });
}
