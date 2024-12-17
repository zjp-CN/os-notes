use io_uring::{IoUring, opcode, types};
use std::io;
use std::time::{Duration, Instant};

fn main() -> io::Result<()> {
    let mut ring = IoUring::new(8)?;

    let mut probe = io_uring::Probe::new();
    if ring.submitter().register_probe(&mut probe).is_err() {
        eprintln!("No probe supported");
    }
    assert!(
        probe.is_supported(opcode::Timeout::CODE),
        "Timeout event is not supported in io uring"
    );

    let now = Instant::now();

    let dur = Duration::from_secs(2);
    let sqe = {
        let time_spec = types::Timespec::new()
            .sec(dur.as_secs())
            .nsec(dur.subsec_nanos());
        opcode::Timeout::new(&time_spec)
            .count(1)
            .build()
            .user_data(0x42)
    };

    // drop(fd);
    // Note that the developer needs to ensure
    // that the entry pushed into submission queue is valid (e.g. fd, buffer).
    unsafe {
        ring.submission()
            .push(dbg!(&sqe))
            .expect("submission queue is full");
    }

    dbg!(ring.submit_and_wait(1)?);

    let cqe = ring.completion().next().expect("completion queue is empty");
    dbg!(now.elapsed());

    assert_eq!(cqe.user_data(), 0x42);

    dbg!(io::Error::from_raw_os_error(-cqe.result()));
    assert!(-cqe.result() == libc::ETIME, "Unknown result",);
    dbg!(cqe);

    Ok(())
}
