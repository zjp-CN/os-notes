mod driver;
mod executor;
mod tcp;
mod timer;

#[cfg(test)]
mod bad;
mod tests;

type Result<T, E = Box<dyn std::error::Error>> = std::result::Result<T, E>;

fn main() {
    executor::Executor::block_on(|spawner| async move {
        spawner.spawn(executor::NaïveTimer::new(1.0));
        spawner.spawn(timer::Timeout::new(std::time::Duration::from_millis(500)));

        spawner.spawn_result(tests::test_tcp_fut());
        spawner.spawn_result(tests::test_file_read());
        spawner.spawn_result(tests::test_file_write_and_read());
    });
}
