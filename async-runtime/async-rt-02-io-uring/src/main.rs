mod bad;
mod driver;
mod executor;
mod tcp;
mod tests;
mod timer;

type Result<T, E = Box<dyn std::error::Error>> = std::result::Result<T, E>;

fn main() {
    const PATH: &str = "Cargo.toml";

    executor::Executor::block_on(|spawner| async move {
        spawner.spawn(executor::NaïveTimer::new(1.0));
        spawner.spawn(timer::Timeout::new(std::time::Duration::from_millis(500)));

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
