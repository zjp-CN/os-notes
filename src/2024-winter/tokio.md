# tokio 源码阅读

## Budget

问题背景：在系统负载不高的情况下，接收资源的速度很快，那么任务在 await 点上一直返回 `Poll::Ready`，从而没有把执行权交还给调度器，因此该任务长时间运行导致其他任务饥饿，并且所有任务的延迟越来越高。

一些可能的解决方法：

1. 使用者可以在自己的代码中插入 `yield_now()` 来强制把执行权还给调度器，从而让其他任务执行。但实际很少有人这么做。
2. 调度器实现抢占：但调度器只在任务的 await 点获取执行权，无法打断正在运行中的任务。

tokio 的解决方法：在每个任务操作上施加预算策略 (budget)。其特点：
* 调度器切换到一个任务时，会重置预算，目前一个任务有 128 个预算；
* 该预算表示连续进行资源操作的最大次数：每操作一次资源，预算减 1；
* 当预算为 0，调度器不再执行该任务，并切换到下一个任务 👉 这就是所谓的自动 yield；
* 每个 tokio 资源（socket、timer、channel）都知道还有多少预算；
  * 只要任务还有剩余预算（预算大于 0），资源就会正常运行；
  * 一旦任务超出预算（预算为 0），所有 tokio 资源将永远返回 not ready（即使背后的 IO 资源已经准备好了）。

因此从另一个角度看，这其实是任务持续地 `Poll::Ready`，在到达次数的上限时，调度器把执行权交给其他任务，从而这实现了一种抢占策略。

注意：
* 预算策略在 tokio 类型上，不是用户感知的：使用者不需要改动基于 tokio 资源的代码就能获得好处。
* 预算策略特定于运行时：tokio 内部的类型知道预算，但外部的类型并不知道，因此如果使用其他库的、没有考虑 tokio 预算的资源类型，那么并不会获得该策略的好处。
* 预算策略涉及的公共 API：
  * [`unconstrained`](https://docs.rs/tokio/latest/tokio/task/fn.unconstrained.html) 用于退出 tokio 的预算策略机制，tokio 对该函数的参数
    Future 不施加任何预算，因此对它不自动 yield。
  * [`consume_budget`](https://docs.rs/tokio/latest/tokio/task/fn.consume_budget.html) 用于消耗 1 个预算，可供外部类型接入预算策略。

`consume_budget` API 不仅适用于资源类型，也适用于计算密集的代码。虽然通常情况下，建议把计算密集的代码放到 blocking 线程，但利用该
API，可以将同步代码变成协作式的任务：

```rust
async fn sum_iterator(input: &mut impl std::iter::Iterator<Item=i64>) -> i64 {
    let mut sum: i64 = 0;
    while let Some(i) = input.next() {
        sum += i;

        // 减少一个预算：当任务的预算减少到 0 时，执行权交给其他任务。
        tokio::task::consume_budget().await
    
        // 当然，也可以不基于预算策略移交执行权，那么使用 yield_now 直接移交。
        // tokio::task::yield_now().await
    }
    sum
}
```

这个预算策略实现的收益：（来自《[Reducing tail latencies with automatic cooperative task yielding (2020)](https://tokio.rs/blog/2020-04-preemption)》）

![](https://user-images.githubusercontent.com/176295/73222456-4a103300-4131-11ea-9131-4e437ecb9a04.png)

master 表示实现前，preempt 表示实现后，延迟最高几乎降低 3 倍。

## 其他资料

* [Rust Runtime 设计与实现-科普篇](https://www.ihcblog.com/rust-runtime-design-1/)： monoio 作者

* [Journey to the Centre of the JVM — Daniel Spiewak](https://www.youtube.com/watch?v=EFkpmFt61Jo&ab_channel=ChariotSolutions)：
  一个异步运行时作者分享他的跨CPU架构debug经历，涉及到汇编, L1/2/3缓存, 内存屏障等等底层概念, 跨物理线程(CPU)的协程间通信。
  Cats-Effect的IO Monad不是poll-based, 意味着取消的时候需要一个信号扔过去告诉它该cancel了。
  他的框架在x86上跑得好好的, 在arm上会随机死锁. 因为arm版jdk的atomic内存屏障跟x86不一样, x86语义更强一些。

* [Zaid Humayun's Blog: Concurrency](https://redixhumayun.github.io/concurrency/)：以及最后的资料清单
* [Zaid Humayun's Blog: Async Runtimes Part II](https://redixhumayun.github.io/async/2024/09/18/async-runtimes-part-ii.html) 
  * [示例：异步运行时](https://github.com/redixhumayun/async-rust)
  * [示例：手写 channel 和 mutex 原语](https://github.com/redixhumayun/rs-examples)

tokio 分析：

* ⭐ 官方公告《[Making the Tokio scheduler 10x faster](https://tokio.rs/blog/2019-10-scheduler)》（2019 年）：
  对调度程序设计进行了高级概述，包括工作窃取调度程序和各种优化。
* ⭐ 官方公告《[Reducing tail latencies with automatic cooperative task yielding](https://tokio.rs/blog/2020-04-preemption)》（2020 年）：
  解释了 tokio 源码里那个奇怪的 budget 设计。
* [Tokio Internals](https://tony612.github.io/tokio-internals) （2021 年）
* 源码阅读会（2021 年，视频）：
  * <https://www.bilibili.com/video/BV1uT4y1R75U>
  * <https://www.bilibili.com/video/BV1yq4y1q7Jc>

