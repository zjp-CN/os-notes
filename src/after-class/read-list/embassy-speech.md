
# Embassy 作者的演讲

## 资料链接

> 视频: [Async Rust in Embedded Systems with Embassy - Dario Nieuwenhuis](https://www.youtube.com/watch?v=H7NtzyP9q8E&ab_channel=RustNederland%28RustNL%29)
> 
> 简介: Async/await in Rust has a unique design compared to other languages that offers much lower-level control.
> This makes it surprisingly well suited for use in microcontroller-based embedded systems with no operating system,
> little memory (down to kilobytes!) and no heap. Embassy is an async runtime that makes that possible:
> it includes an executor that works on no-std no-alloc targets, and libraries to do async IO directly against the hardware.
> In this talk we'll explore how this is done, what challenges arise and how Embassy solves them,
> what makes async on embedded unique compared to a standard async runtime like Tokio,
> and what improvements could we make to the Rust language itself to make it even better.
>
> 幻灯片：[20240507-delft/slides/Async Rust in embedded systems with Embassy - Dario Nieuwenhuis.pdf](https://github.com/rustnl/meetups/blob/main/20240507-delft/slides/Async%20Rust%20in%20embedded%20systems%20with%20Embassy%20-%20Dario%20Nieuwenhuis.pdf)

## 演讲主体内容

我不打算完整整理演讲的主体内容，但这是一些要点总结：

* 背景：嵌入式系统中的微控制器、ARM (M-profile) 、RISC-V、无 OS、内存大小 4kB - 256kB、闪存大小 16kB - 1024kB、无 alloc
* embedded async 的挑战：
  * No alloc!
  * No OS, no file descriptors, no epoll!
* embassy executor：
  * 任务是静态分配的，其大小在编译时已知（不使用引用计数）
  * 通过侵入式链表将任务串起来，然后执行器内的 task queue 指向第一个任务，而第一个任务指向下一个任务等等（不使用 Vec 或者 VecDeque）
* 如何进行 IO 操作：通过 MMIO 和中断机制与外部设备交互

```text
      polls┌──────┐             
    ┌─────►│Future├─────┐       
  ┌─┴──┐   └──────┘     │       
  │Task│                │enables
  └────┘                │       
    ▲ wakes┌─────────┐  │       
    └──────│Interrupt│◄─┘       
           └─────────┘          
```

* Cool things:
  * No reactor! No ecosystem fragmentation, you can mix executor and I/O driver crates.
  * No OS needed! We can use async *instead of* an RTOS. Not on top of it.

---

Problem: DMA and leaking.

```rust
let mut buf = [0u8; 256];
let mut f = serial.read(&mut buf);
poll_once(f).await; // starts DMA
mem::forget(f); // releases the borrow, but doesn't stop DMA
return; // deallocates buf, DMA now corrupts memory
```

Current solution: Just don’t do that ¯\_(ツ)_/¯
- Same problem in io_uring
- Use owned buffers (like Vec) -> can’t because no alloc.
- Use inline buffers (`[u8; 256]`) -> causes bloat due to moves.
- Use static buffers -> unergonomic, requires unsafe for static mut, or overhead of “locked” flags.
- Possible solution: trait Leak / trait Forgettable

---

Embassy current status:
- The executor
- Real-time preemption (cooperative in priority level, preemptive across levels)
- join, select, Mutex, Channel…
- std-like Instant, Duration, sleep, timers.
- TCP/IP networking
- USB
- Bluetooth
- Hardware Abstraction Layers for nRF, STM32, RP2040 MCUs.
- Though you can use any! Espressif’s ESP-HAL has great async support, for example.

## 现场观众提问整理

### RTOS 如何结合 embassy

问 1：RTOS 具有执行严格的最后期限的能力，它如何与 embassy 结合起来？

答：

async 是纯粹的协作式的：对于单个 embassy 执行器和两个任务，如果其中一个任务正在运行，另一个任务因为中断也需要执行，那么必须等待那个运行中的任务结束才能执行另一个任务。

你可以创建多个优先级的 embassy 执行器，高优先级的执行器由中断驱动，然后当高优先级的任务被唤醒时触发一个中断，接着就会触发高优先级的执行器开始轮询这个任务，从而在所有低优先级的任务中抢占成功。

所以，你可以在 RTOS 中得到类似的实时抢占效果，只需要支付一些高优先级执行器带来的延迟，但这基本上是恒定时间的（除非你正在做一些不寻常的事情）。

当然，如果你不能承受这个开销，可以使用原始的中断，然后在同一个程序里结合原始中断和异步来处理优先级不高的事情。

### 加入优先级会如何影响编程

> 笔者注：虽然实际观众的提问和作者的回答有点脱节，但我基于回答的核心内容来取小标题。

问 2：在 async/await 中，代码只在 await 点 yield，但是中断会让代码在任何时刻被打断。这会对编写程序的方式造成什么影响？

答：

在 embassy 执行器内部，所有的东西都是协作式的，并且该执行器类似于单线程，因此执行器里的任务不需要 Send/Sync。

但在多个 embassy 执行器之间，执行不同优先级的任务，这种行为会类似于多线程 —— 无论你以原始的方式还是通过高优先级的方式使用中断。

因为你得到一种可以随时抢占的优先级，这实际上就像在两组指令中，被另一个线程抢占一样。

所以，它既然看起来像线程，那么我们可以使用 Rust 的 Send/Sync 机制：
* 跨优先级发送东西，需要 Send
* 跨线程共享指针，则需要 Sync
* 如果你想通过 Sync 实现内部可变性，则必须使用 mutex，也就是一个临界区 (critical section)，来临时阻止中断，并独占访问数据

这确实影响了编程的方式（笔者注：从单线程编程到多线程编程那样），但 Rust 会保证安全，并且会进行全面的检查，就像在 Linux 的标准线程中那样。

### 理想中的硬件

问 3：你理想中的控制器或者硬件平台或者类似更通用的东西是什么样的。

答：

embassy 的大部分工作是作为一种“硬件反应层”。

但硬件供应商有时会做非常疯狂的事情，比如有的外围设备只能通过阻塞来使用，伴随着奇怪的中断标志，在你读取之后神奇地清除标志，甚至希望你在中断时执行 
IO。这与 embassy 情况不同，因为你使用中断只是为了唤醒，而 IO 工作是在异步任务中完成。

我没有具体的愿望清单。当前的 ARM 中断控制器还不错，而 RISC-V 也更标准化一些。唯一的一件事是，硬件供应商不要坚持定期人工清除中断标志，而是按应有的方式工作。

<details>

<summary>笔者注：ARM GIC</summary>



> ARM的中断控制器，也称为GIC（Generic Interrupt Controller），是ARM架构中用于管理中断信号的重要组成部分。它负责接收来自外部设备或软件生成的中断请求，并将它们分发到相应的CPU核心进行处理。以下是关于ARM GIC中断控制器的一些关键信息：
> 
> 1. **中断类型**：GIC支持多种中断类型，包括软件生成中断（SGI）、私有外设中断（PPI）和共享外设中断（SPI）。其中，SGI用于核心之间的通信，PPI是每个CPU核心独有的，而SPI则是所有CPU核心共享的 。
> 
> 2. **中断优先级**：GIC允许为每个中断设置不同的优先级，确保高优先级的中断能够优先得到处理 。
> 
> 3. **中断触发方式**：GIC支持两种触发方式，边沿触发和电平触发，以适应不同的硬件需求 。
> 
> 4. **中断处理流程**：当CPU接收到中断信号时，它会从用户模式切换到中断处理模式，执行中断处理程序，并在处理完毕后返回到之前的执行状态 。
> 
> 5. **中断控制器的组成**：GIC由分发器（Distributor）和CPU接口（CPU Interface）两大模块组成。分发器负责收集所有中断源并进行处理，而CPU接口则负责将中断分发给相应的CPU核心 。
> 
> 6. **中断状态**：GIC中的中断可以处于不活跃、等待、活跃或活跃并等待等状态，这些状态反映了中断的当前处理情况 。
> 
> 7. **中断ID**：GIC为每个中断源分配一个唯一的中断ID，用于区分和管理不同的中断源 。
> 
> 8. **中断控制器的版本**：GIC有多个版本，从V1到V4，其中V2版本支持ARMv7-A架构，而V3和V4版本支持ARMv8-A/R架构 。
> 
> 9. **中断控制器的编程**：编程GIC涉及打开中断开关、配置中断触发方式、等待中断、获取中断编号、执行中断程序以及通知中断处理完成等步骤 。
> 
> 10. **中断控制器的应用**：GIC广泛应用于ARM架构的单核和多核系统中，用于管理来自硬件外设的中断，并支持虚拟化技术 。
> 
> GIC的设计旨在简化CPU核心的复杂度，实现软中断，以及支持虚拟中断，从而为ARM系统中的中断处理提供了一种高效和灵活的解决方案。
>
> src: Kimi (AI)

</details>

### embassy 版本发布

问 4：我们在生产环境中使用 embassy，感谢你让我们的生活更轻松。由于不是所有的 embassy 库都发布到了
crates.io，我们有时需要 git 依赖。我想知道在适当的发布周期之前，你是不是在等待某些特别的事情。

答：

在今年 1 月，我们已经在 crates.io 上发布了所有 embassy 库的 0.1 版本。从那之后，核心功能并没有什么变化。

在 stm32 上会有更多的更改，因此那上面的发版逾期了。我们计划是定期发版，或许每隔几个月发布。

像协调发布、编写更新日志和博客文章这些事有些烦人，这方面的帮助总是欢迎的。

### 原子上下文中的不安全操作

> 笔者注：最后这个问题来自 Alice，tokio 和 Rust For Linux 的著名贡献者。我没有特别理解提问和回答，所以只是转录。

Alice: 你提到使用 mutex 来防止中断，这让我想起我们在 Linux kernel 中做的一件事情，在原子上下文或者自旋锁临界区中，
如果调用已经休眠的东西，就会遇到麻烦。

Dario: 当你锁定 mutex 的时候会有一个闭包，在那里，任何异步的事情都被阻止了。除此之外，并没有允许或者不允许的事情。
当你查看 mutex 的时候，你拥有内部可变性的完全独占访问，就像常规 Rust 的 mutex 一样。

Alice: 我猜你没有多线程。

Dario: 是的，没有多线程。


