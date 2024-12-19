
## 设计

目标：简单实现，没有复杂的数据结构和任何优化，不考虑高并发，仅仅是一个练习。

* 单线程执行器：MPSC —— 只是为了简单。
* 额外的一个线程操作 io_uring (proactor/事件循环)：通知+任务队列 (Condvar+Mutex)。
* 定时器：
  - [x] （实现 1）在一个单独的线程上调用 sleep，时间到了之后调用 `waker.wake()` —— Async Rust Book 中最朴素的 [唤醒][arb-wakeups]；
  - [x] （实现 2）利用 [`io_uring::Timeout`]，注册超时事件；
* tcp 和文件仅有最基础的读写接口：在 `TcpStream::{read,write}` 和 `File::{read,write}` 背后共享同一个 Op Future 的实现。
* 测试 tcp 读写需要先运行 `cargo r --example tcp_echo`（该代码来自 io-uring crate [示例][tcp_echo]）。

[arb-wakeups]: https://rust-lang.github.io/async-book/02_execution/03_wakeups.html
[`io_uring::Timeout`]: https://docs.rs/io-uring/latest/io_uring/opcode/struct.Timeout.html
[tcp_echo]: https://github.com/tokio-rs/io-uring/blob/c1c37735f3f94f12c773bbec6726d6d3db5ef14e/examples/tcp_echo.rs

```rust
$ find src -name '*.rs' | xargs wc -l | sort -n
   21 src/main.rs
   77 src/tests.rs
   90 src/executor.rs
  102 src/bad.rs
  128 src/timer.rs
  153 src/async_io.rs
  181 src/driver.rs
  752 total
```

## 开发记录

### 难点与解决方式

| 难点/踩坑                                      | 解决方式                                                            |
|------------------------------------------------|---------------------------------------------------------------------|
| 不熟悉各种文件描述符的 flags                   | 阅读 `tokio-uring` 源码；但实际未编写它们                           |
| [闭包不相交捕获字段时的 drop 顺序][drop-order] | 在闭包内使用需要控制 drop 的字段 ([fix][fix-drop])                  |
| 诡异的超时（不发生、错误地发生、随机发生）     | [`*const Timespec`] 必须一直存活直到超时完成  ([fix][fix-Timespec]) |

[drop-order]: https://doc.rust-lang.org/stable/edition-guide/rust-2021/disjoint-capture-in-closures.html#drop-order
[`*const Timespec`]: https://docs.rs/io-uring/latest/io_uring/opcode/struct.Timeout.html#method.new
[fix-drop]: https://github.com/zjp-CN/os-notes/commit/7f4022adda920280008fdaa08e436b001d00e264
[fix-Timespec]: https://github.com/zjp-CN/os-notes/commit/b8647ba049e3f1f2defd8434a9a3965b5916e7df#diff-47455ac29522bfd90d8bb00f886371ef393deeb90980e3d1a99b08893e7e1f6f

### 应基于缓冲区所有权来编写健全的、面向完成的 API

<details>

<summary>不良示例 bad.rs</summary>

```rust
/// Bad practice with borrowed buffer!!! (Though it works.)
fn read_at(path: &str, offset: u64, buf: &mut [u8]) -> impl Future<Output = Result<usize>> {
  ...
}
```

</details>

```rust
// 所有基于 io uring 的成熟库都不会直接支持 referenced slices：
error[E0597]: `a` does not live long enough
   |
21 |         let a = [0; 4];
   |             - binding `a` declared here
22 |         let (result, b) = stream.write(&a[..]).submit().await;
   |                           --------------^-----
   |                           |             |
   |                           |             borrowed value does not live long enough
   |                           argument requires that `a` is borrowed for `'static`
...
28 |     });
   |     - `a` dropped here while still borrowed
```

**The problem: completion, cancellation and buffer management.**

* [IRLO: Forgetting futures with borrowed data (2019)](https://internals.rust-lang.org/t/forgetting-futures-with-borrowed-data/10824)
* [Notes on io-uring by without.boats (2020)](https://without.boats/blog/io-uring/)
* [hyper#2140: Use io_uring for io operations](https://github.com/hyperium/hyper/issues/2140#issuecomment-1869526753)
* [monoio io-cancel](https://github.com/bytedance/monoio/blob/eac666015e3e6d2b6ef235e94b70a9f43a0d3870/docs/zh/io-cancel.md)

缓冲区抽象和设计是一个重要的基础，因为：
* 每种 io-uring 操作需要不同语义的缓冲区 （示例 [`tokio_uring::buf`]、[`monoio::buf`]、[`compio-buf`] ）；
* 必须基于所有权而不是引用来设计接口：在 CQE 完成之前，内核拥有缓冲区的所有权 —— 基于引用的缓冲区在取消任务时容易导致引用失效；
* 严格设计缓冲区的释放时机：Future 拥有缓冲区，并不意味着 drop Future 就释放缓冲区 —— 必须在 CQE 完成之后才能释放它。

[`tokio_uring::buf`]: https://docs.rs/tokio-uring/0.5.0/tokio_uring/buf/index.html
[`monoio::buf`]: https://docs.rs/monoio/0.2.4/monoio/buf/index.html
[`compio-buf`]: https://docs.rs/compio-buf

（但本项目只使用一种 `Vec<u8>` 作为缓冲区，没有编写缓冲区抽象，也没有设计缓冲区严格在 CQE 完成后释放。）
