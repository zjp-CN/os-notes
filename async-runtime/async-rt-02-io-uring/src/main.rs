use io_uring::{IoUring, cqueue::Entry as CQE, squeue::Entry as SQE};
use slab::Slab;
use std::{io::prelude::*, task::Waker};

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

struct Driver {
    uring: IoUring,
    slab: Slab<LifeCycle>,
}

impl Driver {
    fn new() -> Self {
        Driver {
            uring: IoUring::new(128).expect("Failed to initialize io uring."),
            slab: Slab::with_capacity(128),
        }
    }

    /// Submit an IO request: user_data is set up the same as slab index.
    fn submit(&mut self, entry: SQE) -> usize {
        let index = self.slab.insert(LifeCycle::Submitted);
        let entry = entry.user_data(index as u64);

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
        self.uring.submit_and_wait(1).unwrap();
    }

    fn completion(&mut self) {
        for cqe in self.uring.completion() {
            let index = cqe.user_data() as usize;
            let life_cycle = &mut self.slab[index];
            match life_cycle {
                LifeCycle::Submitted => (),
                LifeCycle::Waiting(waker) => waker.wake_by_ref(),
                LifeCycle::Completed(entry) => todo!(),
            }
            *life_cycle = LifeCycle::Completed(cqe);
        }
    }

    fn remove(&mut self, index: usize) {
        self.slab.remove(index);
    }
}

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

struct File {}
