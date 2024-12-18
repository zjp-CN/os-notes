use executor::TimerFuture;
use io_uring::{opcode, types};
use std::{task::Poll, time::Duration};

mod bad;
mod driver;
mod executor;
mod tcp;
mod tests;

type Result<T, E = Box<dyn std::error::Error>> = std::result::Result<T, E>;

fn main() {
    const PATH: &str = "Cargo.toml";

    executor::Executor::block_on(|spawner| async move {
        spawner.spawn(TimerFuture::new(1.0));
        spawner.spawn(Timeout::new(Duration::from_millis(500)));

        spawner.spawn(async {
            let mut buf = vec![0; 1024];
            let read_len = bad::read_at("Cargo.toml", 0, &mut buf).await.unwrap();
            let content = std::str::from_utf8(&buf[..read_len]).unwrap();
            println!("buf 1024:\n{content}");
        });

        spawner.spawn(async {
            println!(
                "async read_to_string:\n{}",
                bad::read_to_string(PATH).await.unwrap()
            );
        });

        spawner.spawn_result(tests::test_tcp_fut());
        spawner.spawn_result(tests::test_file_read());
        spawner.spawn_result(tests::test_file_write_and_read());
    });
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
