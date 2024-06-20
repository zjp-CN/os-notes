记录一些 embassy-sync 库提供的高级同步原语，它们与执行器无关，既可用于 embassy-executor，又可用于其他异步运行时。

# zerocopy_channel (SPSC)

> A zero-copy queue for sending values between asynchronous tasks.
> 
> It can be used concurrently by a producer (sender) and a consumer (receiver), i.e. it is an “SPSC channel”.
> 
> This queue takes a Mutex type so that various targets can be attained. For example, a ThreadModeMutex can be used for single-core Cortex-M targets where messages are only passed between tasks running in thread mode. Similarly, a CriticalSectionMutex can also be used for single-core targets where messages are to be passed from exception mode e.g. out of an interrupt handler.
> 
> This module provides a bounded channel that has a limit on the number of messages that it can store, and if this limit is reached, trying to send another message will result in an error being returned.
>
> src: [embassy_sync::zerocopy_channel](https://docs.embassy.dev/embassy-sync/git/default/zerocopy_channel/index.html) 文档

除了上述文档提到的特点，我还发现 zerocopy_channel 在 API 上一些有趣的设计：
* 提供同步和异步两种方式收发消息

| API                                               | 含义       |
|---------------------------------------------------|------------|
| `fn try_send(&mut Sender) -> Option<&mut T>`      | 同步发送   |
| `async fn send(&mut Sender) -> &mut T`            | 异步发送   |
| `fn send_done(&mut Sender)`                       | 通知已发送 |
| `fn try_receive(&mut Receiver) -> Option<&mut T>` | 同步接收   |
| `async fn receive(&mut Receiver) -> &mut T`       | 异步接收   |
| `fn receive_done(&mut Receiver)`                  | 通知已接收 |

* 发送方通过 `&mut T` 来写入 `T` 值（而不是直接作为参数传递给发送函数）：比如 `let val = sender.send().await; *val = new_value;`
* 执行发送或者接收，必须调用通知函数，否则另一方无法继续（即使缓冲区还有空间，也无法继续）
  * 发送方必须通过调用 send_done 来通知完成发送完成，才能让接收方拿到值
  * 接收方必须通过调用 receive_done 来通知完成接受完成，才能让发送方继续发送
* 双向通道：接收方也可以通过 `&mut T` 写入值让发送方看到，也就是说，消费者和生产者可以原地转换角色，这不同于传统的 SPSC 
* `Channel<'_, M, T>::split(&mut self) -> (Sender<'_, M, T>, Receiver<'_, M, T>)` 使用了一个巧妙的技巧来实现内部可变性：通过将生命周期转移到
  PhantomData，利用裸指针构造 Sender 和 Receiver，它们内部的 channel 为 `&Channel` 而不是 `&mut Channel`（因为借用规则）。此外，还可以注意到
  Sender 和 Receiver 在发送和接收等函数上使用 `&mut self`，这是因为 SPSC 每次只能从缓冲区/切片上对一个元素进行操作（获取、修改、通知），这自然是独占的。
  

```rust
pub struct Channel<'a, M: RawMutex, T> {
    buf: *mut T,
    phantom: PhantomData<&'a mut T>,
    state: Mutex<M, RefCell<State>>,
}

impl<'a, M: RawMutex, T> Channel<'a, M, T> {
    pub fn split(&mut self) -> (Sender<'_, M, T>, Receiver<'_, M, T>) {
        (Sender { channel: self }, Receiver { channel: self })
    }
}

impl<'a, M: RawMutex, T> Sender<'a, M, T> {
    /// Attempts to send a value over the channel.
    pub fn try_send(&mut self) -> Option<&mut T> { ... }

    /// Asynchronously send a value over the channel.
    pub async fn send(&mut self) -> &mut T { ... }

    /// Notify the channel that the sending of the value has been finalized.
    pub fn send_done(&mut self) { ... }
}
```

## 基础示例 

```rust
#use colored::Colorize;
#use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
#use embassy_sync::zerocopy_channel::{self as channel, Channel};
#use embassy_time::Timer;
#
#[embassy_executor::main]
async fn main(spawner: embassy_executor::Spawner) {
    #const N: usize = 2;
    let buf = Box::into_raw(Box::new([0; N]) as Box<[_]>);

    let channel = Box::leak(Box::new(Channel::<'static, CriticalSectionRawMutex, _>::new(unsafe { &mut *buf })));
    let (sender, recv) = channel.split();

    spawner.spawn(consumer(recv)).unwrap();
    spawner.spawn(producer(sender)).unwrap(); // tasks start in reverse order
}

#type Sender = channel::Sender<'static, CriticalSectionRawMutex, i32>;
#type Receiver = channel::Receiver<'static, CriticalSectionRawMutex, i32>;
#
#[embassy_executor::task]
async fn producer(mut sender: Sender) {
    loop {
        let val = sender.send().await;
        #println!("{}", format!("before send: val={val}").white());
        *val += 1;
        #println!("{}", format!("send: val={val}").green().bold());
        sender.send_done();
        Timer::after_secs(1).await;
    }
}

#[embassy_executor::task]
async fn consumer(mut receiver: Receiver) {
    loop {
        let val = receiver.receive().await;
        #println!("{}", format!("recv: val={val}").blue().bold().on_white());
        *val += 2;
        #println!("{}", format!("after recv: val={val}").white());
        receiver.receive_done();
        Timer::after_secs(1).await;
    }
}
```

<details>

<summary>点击展开/收起 打印结果</summary>


```text
before send: val=0
send: val=1
recv: val=1
after recv: val=3
before send: val=0
send: val=1
recv: val=1
after recv: val=3
before send: val=3
send: val=4
recv: val=4
after recv: val=6
before send: val=3
send: val=4
recv: val=4
after recv: val=6
before send: val=6
send: val=7
recv: val=7
after recv: val=9
```

</details>

上面是缓冲 2 个值的情况，如果你设置缓冲 1 个值 (N=1)，能清晰地看到双向通道中的数据传递：

```
before send: val=0
[send] ++1 val=1
recv: val=1
[recv] ++2 val=3
before send: val=3
[send] ++1 val=4
recv: val=4
[recv] ++2 val=6
before send: val=6
[send] ++1 val=7
recv: val=7
[recv] ++2 val=9
```

它在 embassy 项目内部的使用方式见 [embassy-net-driver-channel] 和 [zerocopy example]。

[embassy-net-driver-channel]: https://github.com/embassy-rs/embassy/blob/b0172bb58217d625a13fed8122827b8d0b03c46a/embassy-net-driver-channel/src/lib.rs#L81

[zerocopy example]: https://github.com/embassy-rs/embassy/blob/b0172bb58217d625a13fed8122827b8d0b03c46a/examples/rp/src/bin/zerocopy.rs#L2

## 背压示例

```rust
#use embassy_futures::yield_now;
#use embassy_sync::blocking_mutex::raw::CriticalSectionRawMutex;
#use embassy_sync::zerocopy_channel::{self as channel, Channel};
#use embassy_time as _; // prevent symbol _embassy_time_* from removing due to dead code in linking
#
#const N: usize = 2;
#
#[embassy_executor::main]
async fn main(spawner: embassy_executor::Spawner) {
    let buf = Box::into_raw(Box::new([0; N]) as Box<[_]>);

    let channel = Box::leak(Box::new(Channel::<'static, CriticalSectionRawMutex, _>::new(unsafe { &mut *buf })));
    let (sender, recv) = channel.split();

    spawner.spawn(consumer(recv)).unwrap();
    spawner.spawn(producer(sender)).unwrap(); // tasks start in reverse order
}

#type Sender = channel::Sender<'static, CriticalSectionRawMutex, i32>;
#type Receiver = channel::Receiver<'static, CriticalSectionRawMutex, i32>;
#
#[embassy_executor::task]
async fn producer(mut sender: Sender) {
    let mut send = |n| {
        if let Some(val) = sender.try_send() {
            *val = n;
            println!("send {n}");
            sender.send_done();
        } else {
            println!("send failure: {n}"); // back pressure
        }
    };
    for m in 1..10 {
        for n in 0..N {
            send((n + m * 10) as i32);
        }
        yield_now().await;
    }
}

#[embassy_executor::task]
async fn consumer(mut receiver: Receiver) {
    let mut recv = || {
        if let Some(val) = receiver.try_receive() {
            println!("recv {val}");
            receiver.receive_done();
        }
    };
    loop {
        recv();
        yield_now().await;
    }
}
```

```text
send 10
send 11
recv 10
recv 11
send 20
send 21
send failure: 30
send failure: 31
recv 20
recv 21
send 40
send 41
send failure: 50
send failure: 51
recv 40
recv 41
send 60
send 61
send failure: 70
send failure: 71
recv 60
recv 61
send 80
send 81
send failure: 90
send failure: 91
recv 80
recv 81
```

## 与执行器无关

这里使用 [pollster](https://docs.rs/pollster) 运行时展示：

```rust
//! 亮点：
//! * 非 'static 的方式使用 `embassy_sync::zerocopy_channel::Channel`
//! * 非 embassy-executor 执行器

#![feature(future_join)]

use embassy_sync::{
    blocking_mutex::raw::NoopRawMutex,
    zerocopy_channel::{self as zc, Channel},
};

#[pollster::main]
async fn main() {
    let mut buf = [const { Side::Producer(0) }; BUF_LEN];
    let mut channel = Channel::<NoopRawMutex, _>::new(&mut buf);
    let (tx, rx) = channel.split();

    core::future::join!(consumer(rx), producer(tx)).await;
}

type Sender<'a> = zc::Sender<'a, NoopRawMutex, Side>;
type Receiver<'a> = zc::Receiver<'a, NoopRawMutex, Side>;

#[derive(Debug)]
enum Side {
    Producer(i32),
    Consumer(i32),
}

const BUF_LEN: usize = 1;
const STOP: usize = 10;

async fn producer(mut sender: Sender<'_>) {
    for i in 0..STOP {
        let val = sender.send().await;
        match val {
            Side::Producer(0) => (), // ignore init value
            Side::Producer(_) => eprintln!("Not good: a producer got {val:?}"),
            &mut Side::Consumer(n) => {
                *val = Side::Producer(n + 1);
                println!("[producer] i={i} got={:?}", Side::Consumer(n));
            }
        }
        sender.send_done();
    }
}

async fn consumer(mut receiver: Receiver<'_>) {
    for j in 0..STOP {
        let val = receiver.receive().await;
        match val {
            &mut Side::Producer(n) => {
                *val = Side::Consumer(n + 1);
                println!("[consumer] j={j} got={:?}", Side::Producer(n));
            }
            Side::Consumer(_) => eprintln!("Not good: a consumer got {val:?}"),
        }
        receiver.receive_done();
    }
}
```

```
    BUF_LEN=1 LOOP=9                            BUF_LEN=3 LOOP=9          
[consumer] j=0 got=Producer(0)              [consumer] j=0 got=Producer(0)
[producer] i=1 got=Consumer(1)              [consumer] j=1 got=Producer(0)
[consumer] j=1 got=Producer(2)              [consumer] j=2 got=Producer(0)
[producer] i=2 got=Consumer(3)              [producer] i=3 got=Consumer(1)
[consumer] j=2 got=Producer(4)              [producer] i=4 got=Consumer(1)
[producer] i=3 got=Consumer(5)              [producer] i=5 got=Consumer(1)
[consumer] j=3 got=Producer(6)              [consumer] j=3 got=Producer(2)
[producer] i=4 got=Consumer(7)              [consumer] j=4 got=Producer(2)
[consumer] j=4 got=Producer(8)              [consumer] j=5 got=Producer(2)
[producer] i=5 got=Consumer(9)              [producer] i=6 got=Consumer(3)
[consumer] j=5 got=Producer(10)             [producer] i=7 got=Consumer(3)
[producer] i=6 got=Consumer(11)             [producer] i=8 got=Consumer(3)
[consumer] j=6 got=Producer(12)             [consumer] j=6 got=Producer(4)
[producer] i=7 got=Consumer(13)             [consumer] j=7 got=Producer(4)
[consumer] j=7 got=Producer(14)             [consumer] j=8 got=Producer(4)
[producer] i=8 got=Consumer(15)             [producer] i=9 got=Consumer(5)
[consumer] j=8 got=Producer(16)             [consumer] j=9 got=Producer(6)
[producer] i=9 got=Consumer(17)
[consumer] j=9 got=Producer(18)
```

# MPMC Channel

> Channel - A Multiple Producer Multiple Consumer (MPMC) channel. Each message is only received by a single consumer.
>
> A bounded channel for communicating between asynchronous tasks with backpressure.
> 
> The channel will buffer up to the provided number of messages. Once the buffer is full, attempts to send new messages will wait until a message is received from the channel.
> 
> All data sent will become available in the same order as it was sent.
>
> src: [embassy_sync::channel::Channel](https://docs.embassy.dev/embassy-sync/git/default/channel/struct.Channel.html) 文档

一个有趣的设计是，`Channel` 具有动态分发的形式 `&dyn DynamicChannel<T>`（比如基于此的 `DynamicSender` 和 `DynamicReceiver`），
它擦除了两个类型参数 M （互斥锁类型） 和 N （队列大小），只与 T （传递的数据）有关，这会带来使用上的便利。


```rust
pub struct Channel<M, T, const N: usize>
where
    M: RawMutex,
{
    inner: Mutex<M, RefCell<ChannelState<T, N>>>,
}

impl<M: RawMutex, T, const N: usize> Channel<M, T, N>
{
    /// Get a sender for this channel using dynamic dispatch.
    pub fn dyn_sender(&self) -> DynamicSender<'_, T> {
        DynamicSender { channel: self }
    }

    /// Get a receiver for this channel using dynamic dispatch.
    pub fn dyn_receiver(&self) -> DynamicReceiver<'_, T> {
        DynamicReceiver { channel: self }
    }
}

// trait object: 擦除 Channel 上的 M （互斥锁类型） 和 N （队列大小）
pub(crate) trait DynamicChannel<T> {
    fn try_send_with_context(&self, message: T, cx: Option<&mut Context<'_>>) -> Result<(), TrySendError<T>>;

    fn try_receive_with_context(&self, cx: Option<&mut Context<'_>>) -> Result<T, TryReceiveError>;

    fn poll_ready_to_send(&self, cx: &mut Context<'_>) -> Poll<()>;
    fn poll_ready_to_receive(&self, cx: &mut Context<'_>) -> Poll<()>;

    fn poll_receive(&self, cx: &mut Context<'_>) -> Poll<T>;
}
impl<M: RawMutex, T, const N: usize> Channel<M, T, N> { ... }

/// Send-only access to a [`Channel`] without knowing channel size.
pub struct DynamicSender<'ch, T> {
    pub(crate) channel: &'ch dyn DynamicChannel<T>,
}

/// Receive-only access to a [`Channel`] without knowing channel size.
pub struct DynamicReceiver<'ch, T> {
    pub(crate) channel: &'ch dyn DynamicChannel<T>,
}
```

# 名词解释

结果来自 kimi (AI)，不保证完全准确。

## Backpressure (背压)

在并发编程中，背压（Backpressure）是一种机制，用于处理在数据流或消息传递系统中，生产者（发送方）生成数据的速度超过消费者（接收方）处理数据的速度的情况。背压的目的是防止系统过载，避免资源耗尽，保证系统的稳定性和可靠性。

* 背压的工作原理：

  1. **生产者-消费者模型**：在生产者-消费者模型中，生产者生成数据，消费者处理数据。当消费者处理速度跟不上生产者生成速度时，就需要背压机制介入。

  2. **信号反馈**：消费者通过某种方式向生产者发出信号，告知其处理能力。这可以是直接的反馈信号，也可以是通过队列长度等间接方式。

  3. **生产者调节**：接收到背压信号后，生产者会减少数据生成的速度，或者暂停生成，直到消费者能够赶上。

  4. **动态调整**：背压机制通常需要动态调整，以适应不断变化的系统负载和处理能力。

* 背压的实现方式：

  1. **阻塞队列**：使用阻塞队列，当队列满时，生产者会被阻塞，直到队列中有空间。

  2. **流控制**：在流式处理系统中，如Reactive Streams，通过请求-响应模式来控制数据流。

  3. **信用模型**：在某些协议中，如TCP，使用信用模型来控制数据的发送，接收方告诉发送方可以发送多少数据。

  4. **限流算法**：如令牌桶算法或漏桶算法，通过控制数据生成或传输的速率来实现背压。

  5. **资源池管理**：通过动态调整资源池的大小，如线程池或连接池，来适应当前的负载。

* 背压的重要性：

  - **防止系统过载**：避免因处理能力不足而导致的系统崩溃。
  - **提高资源利用率**：合理分配资源，避免资源浪费。
  - **保证服务质量**：通过控制数据流，保证系统的响应时间和吞吐量。

背压是并发编程中一个重要的概念，正确实现背压机制对于构建高效、稳定和可扩展的系统至关重要。

## SPSC

SPSC（Single-Producer Single-Consumer）通道是一种特定的队列，它被设计为只由一个生产者（Producer）和一个消费者（Consumer）访问。这种设计模式可以提供高效率的数据交换，因为它避免了多线程环境下的锁竞争和同步开销。

* SPSC通道的特点：

  1. **无锁设计**：由于只有一个生产者和一个消费者，SPSC通道通常不需要使用锁来保护数据结构，从而减少了锁的开销。

  2. **线程安全**：尽管没有锁，但SPSC通道在设计上保证了线程安全，因为只有一个生产者和一个消费者，所以不会出现数据竞争的问题。

  3. **高吞吐量**：由于没有同步开销，SPSC通道可以提供很高的数据吞吐量。

  4. **低延迟**：无锁设计还可以减少延迟，因为生产者和消费者不需要等待锁的释放。

  5. **简单性**：SPSC通道的实现相对简单，因为只需要考虑单向的数据流。

* SPSC通道的实现：

  1. **环形缓冲区**：SPSC通道通常使用环形缓冲区（Ring Buffer）来存储数据。生产者在缓冲区的一端添加数据，消费者从另一端取出数据。

  2. **索引管理**：生产者和消费者各自维护一个索引来跟踪它们在环形缓冲区中的位置。

  3. **边界条件处理**：当生产者或消费者到达环形缓冲区的末端时，需要正确处理边界条件，以确保数据的正确插入和取出。

  4. **内存对齐**：为了提高性能，SPSC通道的实现通常会考虑内存对齐和缓存行的使用。

  5. **避免伪共享**：在多核处理器上，避免伪共享（False Sharing）也是提高性能的关键。

* 使用场景：

  - **实时系统**：在需要高吞吐量和低延迟的实时系统中，SPSC通道可以提供优秀的性能。
  - **消息传递**：在多线程或多进程间的消息传递中，SPSC通道可以作为一种高效的通信机制。
  - **数据流处理**：在需要高效数据流处理的场景中，例如视频编码、网络数据传输等。

SPSC通道是一种高效的并发数据结构，适用于特定的单生产者单消费者场景。然而，它并不适用于多生产者或多消费者的场景，这些场景可能需要更复杂的同步机制或不同的数据结构。

## Two-Way Channel / Bidirectional Queue

双向通道或双端队列是一种数据结构，允许两个端点（通常称为端点A和端点B）进行双向通信。这种队列可以看作是两个SPSC队列的组合，每个端点都有一个独立的发送和接收队列。以下是双向通道或双端队列的一些关键特点：

1. **独立队列**：每个端点都有自己的发送队列和接收队列。端点A可以向自己的发送队列中添加数据，端点B可以从端点A的接收队列中取出数据；反之亦然。

2. **无阻塞通信**：如果设计得当，双向通道可以实现无阻塞通信，即生产者和消费者可以继续工作而不会被对方阻塞。

3. **同步机制**：尽管每个端点都有自己的队列，但在某些情况下可能需要同步机制来确保数据的一致性和完整性。

4. **角色可转换**：在某些实现中，端点可以在发送者和接收者之间转换角色，这要求通道能够处理这种角色转换。

5. **流控制**：双向通道可能需要更复杂的流控制机制，以确保数据的发送和接收速率相匹配，避免缓冲区溢出或饥饿。

6. **低延迟**：设计良好的双向通道可以提供低延迟的通信，这对于实时系统或高性能应用非常重要。

7. **高吞吐量**：通过优化数据结构和同步机制，双向通道可以实现高吞吐量的数据处理。

8. **适用场景**：双向通道适用于需要端点之间进行频繁、双向通信的场景，如对等网络、实时通信系统、分布式计算等。

实现双向通道或双端队列时，需要考虑以下方面：

- **数据结构**：选择合适的数据结构来存储发送和接收队列中的数据。
- **同步和锁**：确定是否需要使用锁或其他同步机制来保护共享数据。
- **性能优化**：通过减少锁的使用、优化内存访问和利用现代CPU架构来提高性能。
- **错误处理**：设计错误处理机制来处理通信过程中可能出现的问题，如缓冲区溢出、数据损坏等。
- **API设计**：设计简洁直观的API，使得端点可以方便地发送和接收数据。

双向通道或双端队列是一种灵活的通信机制，可以在多种应用场景中实现高效的数据交换。然而，它的实现比单向通道更复杂，需要仔细设计以确保性能和可靠性。
