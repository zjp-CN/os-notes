use crate::driver;
use io_uring::{opcode, types};
use std::{task::Poll, time::Duration};

#[allow(dead_code)]
pub struct Timeout {
    time_spec: Box<types::Timespec>,
    duration: Duration,
    index: usize,
}

impl Timeout {
    pub fn new(duration: Duration) -> Self {
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
    crate::executor::Executor::block_on(|spawner| async move {
        spawner.spawn(Timeout::new(Duration::from_secs(5)));
        spawner.spawn(Timeout::new(Duration::from_secs(3)));
        spawner.spawn(Timeout::new(Duration::from_secs(1)));
        spawner.spawn(Timeout::new(Duration::from_millis(100)));
    });
}

pub use naïve::NaïveTimer;
mod naïve {
    use std::{
        pin::Pin,
        sync::{Arc, Mutex},
        task::{Poll, Waker},
        thread,
        time::Duration,
    };

    struct SharedState {
        duration: f32,
        complete: bool,
        waker: Option<Waker>,
    }

    pub struct NaïveTimer {
        state: Arc<Mutex<SharedState>>,
    }

    impl Future for NaïveTimer {
        type Output = ();

        fn poll(
            self: Pin<&mut Self>,
            cx: &mut std::task::Context<'_>,
        ) -> std::task::Poll<Self::Output> {
            let mut shared_state = self.state.lock().unwrap();
            if shared_state.complete {
                println!("Ready: Timer for {} secs", shared_state.duration);
                Poll::Ready(())
            } else {
                println!("Pending: Timer for {} secs", shared_state.duration);
                // set a waker which wakes up the task on completion
                shared_state.waker = Some(cx.waker().clone());
                Poll::Pending
            }
        }
    }

    impl NaïveTimer {
        pub fn new(secs: f32) -> Self {
            let state = Arc::new(Mutex::new(SharedState {
                duration: secs,
                complete: false,
                waker: None,
            }));
            thread::spawn({
                let state = state.clone();
                move || {
                    println!("Sleep for {secs} sec");
                    thread::sleep(Duration::from_secs_f32(secs));
                    let mut lock = state.lock().unwrap();
                    lock.complete = true;

                    // wake up the task by sending the future to executor
                    lock.waker.take().unwrap().wake();
                    println!("Completed for {secs} sec");
                }
            });
            NaïveTimer { state }
        }
    }
}
