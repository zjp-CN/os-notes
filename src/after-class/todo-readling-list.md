# 待阅读清单

个人搜集的[^personal]、关于 Rust 和操作系统材料（与训练营无关）。


* [Philipp Oppermann's blog: Writing an OS in Rust](https://os.phil-opp.com/)：这应该无人不晓吧...
  * This Month in Rust OSDev：Rust OS 开发月报，就在 Philipp 的博客里面，基本是 Rust + OS 的社区动态总结（比如来自社区项目代码和博客）
* [Redox]：a Unix-like Operating System written in Rust, aiming to bring the innovations of Rust to a modern microkernel and full set of applications.
* [EuraliOS](https://github.com/bendudson/EuraliOS/blob/main/doc/journal/)
  * A hobby x86-64 operating system written in Rust
  * Disclaimer: This was written by someone who doesn’t (or didn’t) know anything about Rust or operating systems.
    The result is probably not idiomatic Rust or a sensible OS design.
    If you are looking for a usable operating system implemented in Rust then [Redox] OS is probably what you want.

[Redox]: https://www.redox-os.org/

[^personal]: 这几年我浏览的 Rust + OS 的帖子不少，但从未想过搜集起来，从现在开始列一份清单吧，像我入门 
Rust [那样](https://www.yuque.com/zhoujiping/programming/rust-materials)  吧：）

一些待阅读的、具体的、有趣的文章：
* [How to work with !Sized types in Rust](https://sgued.fr/blog/heapless-howto/)：来自嵌入式流行库 heapless 的
  [VecView PR](https://github.com/rust-embedded/heapless/pull/425) 作者，看起来涉及 const generics/unsafe 等高级主题。

# rust-embedded 项目

* [The Embedded Rust Book](https://docs.rust-embedded.org/book)
  * [Who This Book is For](https://docs.rust-embedded.org/book/#who-this-book-is-for)：适合于具有嵌入式和 Rust 背景的人
  * [Other Resources](https://docs.rust-embedded.org/book/#other-resources)：对于缺乏嵌入式背景的人的资料

# 向老师相关

* [赵方亮：操作系统中的异步与任务调度机制研究](https://www.yuque.com/xyong-9fuoz/hg8kgr/xd49izet7xd38gdy)
  * [repo: rCore-N](https://github.com/CtrlZ233/rCore-N)
* [车春池：基于Rust的io-uring实现](https://www.yuque.com/xyong-9fuoz/hg8kgr/rstmxmyv1zutm84y#7774d41c)
  * [repo: Emma](https://github.com/sekirio-rs/Emma)

# 已阅读清单

## RTIC + Embassy HAL

社区讨论：《[RTIC + Embassy/other-HAL for STM32?](https://www.reddit.com/r/rust/comments/1dtiqja/embedded_beginner_rtic_embassyotherhal_for_stm32/)》

> **背景补充：**
>
> 在嵌入式领域，RTIC（Real-Time Interrupt-driven Concurrency）是一个专为ARM Cortex-M微控制器设计的Rust框架，它提供了一种简单、高效的方式来管理和执行实时任务。RTIC的核心思想是利用微控制器的中断系统来驱动任务的执行，确保任务能够在预定的时间内完成。
> 
> RTIC框架的主要特点包括：
> 1. **实时性**：确保任务的实时性，任务可以在预定的时间内开始和完成。
> 2. **并发性**：通过中断实现多任务的并发执行。
> 3. **低开销**：针对ARM Cortex-M微控制器优化，运行时开销低。
> 4. **灵活性**：允许开发者为每个任务设置优先级，确保关键任务优先执行。
> 
> RTIC的优点在于它的简便性，开发过程中主要关注三个方面：
> - 中断驱动：任务调用源于硬件中断，形成事件-响应模型。
> - 数据隔离：数据分为本地和共享两类，确保数据安全和访问逻辑清晰。
> - 优先级：依靠MCU进行任务调度，优先级是RTIC工作的基础。
> 
> 然而，RTIC的缺点也很明显，它过于简单，对Rust特性的支持不足，面对复杂任务时显得力不从心。RTIC中的任务参数通过宏扩展写出来，难以按需调度，对状态机、控制台命令、远程控制等功能不够友好。此外，RTIC使用过程宏进行任务和数据的扩展，限制了与其他过程宏的衔接。
> 
> 与RTIC相比，Embassy是另一种Rust嵌入式开发框架，它基于Rust的异步特性（async/await、Send等）实现线程化并确保安全。Embassy提供了强大的线程间通信手段，任务创建更灵活，但需要程序员自己承担线程间数据保护的责任。
> 
> 总的来说，RTIC为嵌入式开发提供了一种中断驱动的实时任务调度思想，易于上手，适合固定功能的嵌入式开发。而Embassy则更灵活、强大，充分发挥了Rust语言的优势，但对程序员提出了更高的要求。
>
> src: kimi (AI)

