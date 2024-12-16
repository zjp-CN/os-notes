#![allow(unused)]

use io_uring::{IoUring, cqueue::Entry as CQE, opcode, squeue::Entry as SQE, types};
use slab::Slab;
use std::{
    cell::RefCell,
    fs::{File as StdFile, OpenOptions},
    future::poll_fn,
    io::{self, Result, prelude::*},
    mem::ManuallyDrop,
    os::fd::AsRawFd,
    task::{Poll, Waker},
};

mod executor;

fn main() -> Result<()> {
    executor::Executor::block_on(|_| async {
        let buf = File::read("Cargo.toml").await.unwrap();
        let content = String::from_utf8(buf).unwrap();
        println!("{content}");
    });

    Ok(())
}

struct Driver {
    uring: IoUring,
    slab: Slab<LifeCycle>,
}

thread_local! {
    static DRIVER: RefCell<Driver> = RefCell::new(Driver::new());
}

impl Driver {
    fn new() -> Self {
        Driver {
            uring: IoUring::new(128).expect("Failed to initialize io uring."),
            slab: Slab::with_capacity(128),
        }
    }

    /// Submit an IO request: user_data is set up the same as slab index.
    fn submit(&mut self, sqe: SQE) -> usize {
        let index = self.slab.insert(LifeCycle::Submitted);
        let entry = sqe.user_data(index as u64);

        // safety: must ensure entry is valid
        unsafe {
            self.uring
                .submission()
                .push(&entry)
                .expect("submission queue is full")
        };
        index
    }

    /// Block the thread until at least one IO complets.
    fn wait(&self) {
        dbg!(self.uring.as_raw_fd());
        self.uring.submit_and_wait(1).unwrap();
    }

    fn completion(&mut self) {
        for cqe in self.uring.completion() {
            let index = cqe.user_data() as usize;
            dbg!(index);
            let life_cycle = &mut self.slab[index];
            match life_cycle {
                LifeCycle::Submitted => (),
                LifeCycle::Waiting(waker) => waker.wake_by_ref(),
                LifeCycle::Completed(entry) => println!("index={index} already completed"),
            }
            *life_cycle = LifeCycle::Completed(cqe);
        }
    }

    fn remove(&mut self, index: usize) {
        self.slab.remove(index);
    }
}

// fn reactor() -> impl Future<Output = ()> {
//     poll_fn(|cx| {
//     DRIVER.with(|d| {
//         if let Ok(driver) = d.try_borrow_mut() {
//             driver.uring.submitter().wa
//         } else {
//                 cx.waker().wake_by_ref();
//             }
//     })
//     })
// }

#[derive(Debug)]
enum LifeCycle {
    Submitted,
    Waiting(Waker),
    Completed(CQE),
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
            let index = DRIVER.with(|d| d.borrow_mut().submit(sqe));

            File {
                file: Some(file),
                op: Op {
                    index,
                    buffer: Some(buffer),
                },
            }
        };

        poll_fn(move |cx| {
            let cqe = DRIVER.with(|d| {
                let driver = &mut *d.borrow_mut();
                let life_cycle = driver.slab.get_mut(file.op.index).unwrap();
                dbg!(&life_cycle);
                let cx_waker = cx.waker();
                match life_cycle {
                    LifeCycle::Submitted => *life_cycle = LifeCycle::Waiting(cx_waker.clone()),
                    LifeCycle::Waiting(waker) if waker.will_wake(cx_waker) => (),
                    LifeCycle::Waiting(waker) => *life_cycle = LifeCycle::Waiting(cx_waker.clone()),
                    // LifeCycle::Waiting(waker) => waker.wake_by_ref(),
                    LifeCycle::Completed(entry) => return Some(entry.clone()),
                };
                driver.wait();
                // dbg!(driver.uring.submitter().submit());
                driver.completion();
                None
            });
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
