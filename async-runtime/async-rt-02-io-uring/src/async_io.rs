use crate::driver;
use io_uring::{opcode, types};
use std::{
    fs::OpenOptions,
    io::{self, Result},
    net::{SocketAddr, TcpStream as StdTcpStream},
    os::fd::{AsRawFd, OwnedFd, RawFd},
    pin::Pin,
    sync::Arc,
    task::{Context, Poll},
};

#[derive(Debug, Clone)]
struct ArcFd {
    inner: Arc<OwnedFd>,
}

impl ArcFd {
    fn as_raw_fd(&self) -> RawFd {
        self.inner.as_raw_fd()
    }

    fn new(fd: OwnedFd) -> Self {
        ArcFd {
            inner: Arc::new(fd),
        }
    }
}

pub struct TcpStream {
    fd: ArcFd,
}

impl TcpStream {
    pub fn connect(addr: SocketAddr) -> Result<Self> {
        let fd = ArcFd::new(StdTcpStream::connect(addr)?.into());
        Ok(TcpStream { fd })
    }

    pub async fn read(&self, buf: Vec<u8>) -> BufResult {
        Op::read(self.fd.clone(), buf).await
    }

    pub async fn write(&self, buf: Vec<u8>) -> BufResult {
        Op::write(self.fd.clone(), buf).await
    }
}

pub struct File {
    fd: ArcFd,
}

impl File {
    pub fn open(path: &str, with: impl FnOnce(&mut OpenOptions)) -> Result<Self> {
        let mut opt = OpenOptions::new();
        with(&mut opt);
        opt.read(true);
        let fd = ArcFd::new(opt.open(path)?.into());
        Ok(File { fd })
    }

    pub async fn read(&self, buf: Vec<u8>) -> BufResult {
        Op::read(self.fd.clone(), buf).await
    }

    pub async fn write(&self, buf: Vec<u8>) -> BufResult {
        Op::write(self.fd.clone(), buf).await
    }
}

struct Op {
    index: usize,
    buf: Option<Vec<u8>>,
    fd: Option<ArcFd>,
}

impl Op {
    /// safety: buf should be fully initialized
    fn read(fd: ArcFd, mut buf: Vec<u8>) -> Self {
        let sqe = opcode::Read::new(
            types::Fd(fd.as_raw_fd()),
            buf.as_mut_ptr(),
            buf.len() as u32,
        )
        .offset(0)
        .build();
        let index = driver::submit(sqe);
        Self {
            index,
            buf: Some(buf),
            fd: Some(fd),
        }
    }

    /// safety: buf should be fully initialized
    fn write(fd: ArcFd, buf: Vec<u8>) -> Self {
        let sqe = opcode::Write::new(types::Fd(fd.as_raw_fd()), buf.as_ptr(), buf.len() as u32)
            .offset(0)
            .build();
        let index = driver::submit(sqe);
        Self {
            fd: Some(fd),
            index,
            buf: Some(buf),
        }
    }
}

type BufResult = (Result<usize>, Vec<u8>);

impl Future for Op {
    type Output = BufResult;

    fn poll(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Self::Output> {
        let index = self.index;
        let Some(cqe) = driver::poll(index, cx.waker()) else {
            return Poll::Pending;
        };

        let buf = self.buf.take().expect("Buffer has been taken.");

        // Release resources like cqe slab node and referenced socket fd.
        driver::remove(index);
        match self.fd.take() {
            Some(fd) => drop(fd),
            None => return custom_io_err("Fd has been taken.", buf),
        };

        let res = cqe.result();
        let read_len = if res < 0 {
            return io_err(res, buf);
        } else {
            res as usize
        };

        assert!(
            read_len <= buf.len(),
            "Bytes filled exceed the buffer length."
        );

        Poll::Ready((Ok(read_len), buf))
    }
}

fn io_err<T>(neg: i32, buf: Vec<u8>) -> Poll<(Result<T>, Vec<u8>)> {
    let err = Err(io::Error::from_raw_os_error(-neg));
    Poll::Ready((err, buf))
}

fn custom_io_err<T>(err: impl Into<String>, buf: Vec<u8>) -> Poll<(Result<T>, Vec<u8>)> {
    let err = Err(io::Error::new(io::ErrorKind::Other, err.into()));
    Poll::Ready((err, buf))
}
