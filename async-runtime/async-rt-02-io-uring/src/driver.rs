use io_uring::{IoUring, cqueue::Entry as CQE, squeue::Entry as SQE};
use slab::Slab;
use std::{
    sync::{Arc, Condvar, LazyLock, Mutex},
    task::Waker,
    thread,
    time::Duration,
};

#[derive(Debug)]
pub enum LifeCycle {
    Submitted,
    Waiting(Waker),
    Completed(CQE),
}

struct CqeAlloc {
    slab: Slab<LifeCycle>,
}

impl CqeAlloc {
    /// Submit an IO request: user_data is set up the same as slab index.
    fn submit(&mut self, sqe: SQE) -> (usize, SQE) {
        let index = self.slab.insert(LifeCycle::Submitted);
        let cqe = sqe.user_data(index as u64);
        (index, cqe)
    }

    fn completion(&mut self, v_cqe: &[CQE]) {
        for cqe in v_cqe {
            let index = cqe.user_data() as usize;
            dbg!(index);
            let life_cycle = &mut self.slab[index];
            match life_cycle {
                LifeCycle::Submitted => (),
                LifeCycle::Waiting(waker) => waker.wake_by_ref(),
                LifeCycle::Completed(_entry) => println!("index={index} already completed"),
            }
            *life_cycle = LifeCycle::Completed(cqe.clone());
        }
    }

    fn poll(&mut self, index: usize, cx_waker: &Waker) -> Option<CQE> {
        let life_cycle = self.slab.get_mut(index).unwrap();
        dbg!(index, &life_cycle);
        match life_cycle {
            LifeCycle::Submitted => *life_cycle = LifeCycle::Waiting(cx_waker.clone()),
            LifeCycle::Waiting(waker) if waker.will_wake(cx_waker) => (),
            LifeCycle::Waiting(_) => *life_cycle = LifeCycle::Waiting(cx_waker.clone()),
            LifeCycle::Completed(entry) => return Some(entry.clone()),
        };
        None
    }

    fn remove(&mut self, index: usize) {
        self.slab.remove(index);
    }
}

#[derive(Clone)]
struct Driver {
    inner: Arc<Inner>,
}

impl Driver {
    fn new() -> Self {
        Driver {
            inner: Arc::new(Inner {
                data: Mutex::new(Data {
                    alloc: CqeAlloc {
                        slab: Slab::with_capacity(64),
                    },
                    v_sqe: Vec::new(),
                }),
                condvar: Condvar::new(),
            }),
        }
    }

    fn with<T>(&self, f: impl FnOnce(&mut Data) -> T) -> T {
        f(&mut self.inner.data.lock().unwrap())
    }

    pub fn submit(&self, sqe: SQE) -> usize {
        let mut lock = self.inner.data.lock().unwrap();
        let (index, sqe) = lock.alloc.submit(sqe);
        lock.v_sqe.push(sqe);
        drop(lock);
        self.inner.condvar.notify_all();
        index
    }

    fn wait_v_sqe(&self) -> Vec<SQE> {
        let guard = self.inner.data.lock().unwrap();
        let dur = Duration::from_millis(100);
        let wait_timeout = self.inner.condvar.wait_timeout(guard, dur);
        std::mem::take(&mut wait_timeout.unwrap().0.v_sqe)
    }

    fn completion(&self, v_cqe: &[CQE]) {
        self.inner.data.lock().unwrap().alloc.completion(v_cqe);
    }
}

struct Inner {
    data: Mutex<Data>,
    condvar: Condvar,
}

struct Data {
    alloc: CqeAlloc,
    v_sqe: Vec<SQE>,
}

#[allow(dead_code)]
struct Reactor {
    handle: thread::JoinHandle<()>,
    driver: Driver,
}

impl Reactor {
    fn new() -> Self {
        let driver = Driver::new();
        let handle = thread::spawn({
            let driver = driver.clone();
            move || {
                let mut v_cqe = Vec::new();
                let mut uring = IoUring::new(128).expect("Failed to initialize io uring.");
                loop {
                    // handle submission
                    let v_sqe = driver.wait_v_sqe();
                    // safety: must ensure entries are valid
                    unsafe {
                        uring
                            .submission()
                            .push_multiple(&v_sqe)
                            .expect("Submission queue is full.")
                    };

                    // handle completion
                    let completed_n = uring.submit_and_wait(1).unwrap();
                    dbg!(completed_n);
                    v_cqe.extend(uring.completion());
                    driver.completion(&v_cqe);
                    v_cqe.clear();
                }
            }
        });
        Reactor { handle, driver }
    }
}

fn driver() -> &'static Driver {
    static DRIVER: LazyLock<Reactor> = LazyLock::new(Reactor::new);
    &DRIVER.driver
}

pub fn submit(sqe: SQE) -> usize {
    driver().submit(sqe)
}

pub fn poll(index: usize, cx_waker: &Waker) -> Option<CQE> {
    driver().with(|data| data.alloc.poll(index, cx_waker))
}

pub fn remove(index: usize) {
    driver().with(|data| data.alloc.remove(index));
}
