
## 设计

目标：简单实现，没有复杂的数据结构和任何优化，不考虑高并发，仅仅是一个练习。

* 单线程执行器：MPSC。
* 额外的一个线程操作 io_uring (reactor/事件循环)：通知+任务队列 (Condvar+Mutex)。
* 定时器：
  - [x] （实现 1）在一个单独的线程上调用 sleep，时间到了之后调用 `waker.wake()` —— Async Rust Book 中最朴素的 [唤醒][arb-wakeups]；
  - [x] （实现 2）利用 [`io_uring::Timeout`]，注册超时事件；
  - [ ] （未实现）时间轮。
* tcp 和文件仅有最基础的读写接口：在 `TcpStream::{read,write}` 和 `File::{read,write}` 背后共享同一个 Op Future 的实现。
* 测试 tcp 读写需要先运行 `cargo r --example tcp_echo`（该代码来自 io-uring crate [示例][tcp_echo]）。

[arb-wakeups]: https://rust-lang.github.io/async-book/02_execution/03_wakeups.html
[`io_uring::Timeout`]: https://docs.rs/io-uring/latest/io_uring/opcode/struct.Timeout.html
[tcp_echo]: https://github.com/tokio-rs/io-uring/blob/c1c37735f3f94f12c773bbec6726d6d3db5ef14e/examples/tcp_echo.rs

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

### 应基于缓冲区所有权来编写健全的面向完成的 API

<details>

<summary>不良示例 bad.rs</summary>

```rust
/// Bad practice with borrowed buffer!!! (Though it works.)
fn read_at(path: &str, offset: u64, buf: &mut [u8]) -> impl Future<Output = Result<usize>> {
  ...
}
```

</details>

`tokio-uring` 的 [buffer](https://docs.rs/tokio-uring/0.5.0/tokio_uring/buf/index.html) 抽象排除了 `&'a [u8]`
（除非 `'a = 'static`）和 `&'a mut [u8]`。

```rust
error[E0597]: `a` does not live long enough
  --> examples/tcp_stream.rs:22:41
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


《[IRLO: Forgetting futures with borrowed data (2019)](https://internals.rust-lang.org/t/forgetting-futures-with-borrowed-data/10824)》

**The problem: completion, cancellation and buffer management.**

> 逻辑所有权是在 Rust 当前类型系统中实现此功能的唯一方法：内核必须拥有缓冲区。
> 没有可靠的方法可以获取借用的切片，将其传递给内核，并等待内核完成其上的 IO，
> 从而保证并发运行的用户程序不会以不同步的方式访问缓冲区。
> Rust 的类型系统除了传递所有权之外无法对内核的行为进行建模。
> 我强烈鼓励每个人转向基于所有权的模型，因为我非常有信心这是创建 API 的唯一健全方法。
>
> 而且，这实际上是有利的。io-uring 有很多 API，它们的数量和复杂性都在不断增长，都是围绕允许内核为您管理缓冲区而设计的。
> 通过所有权传递缓冲区允许我们访问这些 API，并且从长远来看无论如何这将是性能最高的解决方案。
> 让我们接受内核拥有缓冲区的事实，并在该接口之上设计高性能 API。
> 
> src: 《[Notes on io-uring by without.boats (2020)](https://without.boats/blog/io-uring/)》


`tokio-uring` 的异步 IO API 完全基于 `<T: BoundedBufMut>` 👍 所有权缓冲区设计，这是必要的。例如：

```rust
// src: https://docs.rs/tokio-uring/0.5.0/tokio_uring/buf/struct.Slice.html
pub struct Slice<T> {
    buf: T,
    begin: usize,
    end: usize,
}
// 👇
pub struct Slice {
    buf: Vec<u8>,
    begin: usize,
    end: usize,
}
```

如果没有这个 owned `Slice` 来管理写入缓冲区的位置，那么实现类似 bad.rs 中的 `read_to_string` 只能在每个循环中传入新的缓冲区，这会很低效。

（当我试图把 read_to_string 实现放到基于 Vec 的 read_at 的接口上才意识到抽象缓冲区很重要，但最终并没有编写这部分代码。）
