# rCore 定时器与 embassy 

**将 embassy 应用于 rCore 定时器。**

修改了 user 目录下的代码，所以获取本仓库时这样做：

```shell
git clone --recurse-submodules https://gitee.com/ZIP97/rCore-tutorial-code-2024S-embassy.git
```

# 核心思路和代码修改

核心思路：在 rCore 的时钟中断处理函数中，嵌入 embassy 运行时。

具体在 `set_next_trigger` 中函数，将原来的 `set_timer` 函数移至 `<TimerDriver as embassy_time_driver::Driver>::set_alarm` 
函数中，并将设置定时作为了一个异步任务，从而不仅可以实现原来的 rCore 的定时逻辑，更重要的是内核支持了任何异步任务。

> 为了聚焦于实验的重点，我们采用更长的时间片来减少时间中断的次数，来观察两个用户态程序在 sleep 期间，内核的定时任务打印的执行情况。
> 而不是采用 rCore 原来的设定的 1 秒钟打断 100 次作为定时任务。

主要的代码修改在 `src/timer.rs` 模块：
* 设置 embassy 运行时：添加一个 `embassy_runtime` 函数，通过全局静态变量，初始化执行器
* 声明一些异步任务，比如设置定时打印任务，然后将任务注册到执行器（通过 `Spawner` 的 `spawn` 函数）
* 调用一次 [`Executor::poll`] 函数，轮询所有被注册的、但未被完成的任务：
  * 在轮询过程中，这些异步任务会被推进一步，直至这些任务完成（完成的标志为 `Future::poll` 返回 Ready，然后该任务状态不再是 spawned）
  * 由于目前只调用一次 `Executor::poll`，这些异步任务不一定直接推进到完成，也就是说，异步任务可能会在未来进入时钟中断后的轮询中才完成

具体对于定时打印任务来说，它向执行器注册后，调用了 [`<Timer as Future>::poll`]，这个 Future 实现会把它放进执行器内部的定时任务栈；
由于将来某个时刻才到期，那么该任务处于 Pending 状态而进入“睡眠”，其 CPU 执行权交还给执行器来推进其他任务（如果还有任务的话）；
当设定的时刻到来，硬件会产生定时器中断信号，然后交由内核态的 ISR 处理时钟中断，于是 CPU 执行权来到 `Executor::poll`，推进这个定时任务从而打印了内容。

rCore 的时钟处理和 embassy 之间的关联：定时操作变成了异步任务。依然由硬件触发时间中断，但处理时间中断的逻辑由 embassy 异步运行时管理，从同步变成了异步。

[`Executor::poll`]: https://docs.embassy.dev/embassy-executor/git/riscv32/raw/struct.Executor.html#method.poll
[`<Timer as Future>::poll`]: https://docs.embassy.dev/embassy-time/git/default/struct.Timer.html#method.poll

```rust
// 定时器驱动
struct TimerDriver {}

impl Driver for TimerDriver {
    fn now(&self) -> u64 { riscv::register::time::read64() }

    // 该函数会在 embassy-executor 轮询一遍所有异步任务之后被调用
    fn set_alarm(&self, _alarm: AlarmHandle, timestamp: u64) -> bool {
        let set = self.now() < timestamp;
        if set {
            set_timer(timestamp as usize);
        }
        set
    }
}
```

```rust
/// Set the next timer interrupt
pub fn set_next_trigger() {
    embassy_runtime();

    // 原 rCore 的 set_timer，现放置于 <TimerDriver as Driver>::set_alarm 函数中
    // set_timer(get_time() + CLOCK_FREQ / TICKS_PER_SEC);
}

fn embassy_runtime() {
    embassy_time_driver::time_driver_impl!(static DRIVER: TimerDriver = TimerDriver{});

    static mut RUNTIME: Option<Executor> = None;
    let runtime = unsafe {
        RUNTIME.get_or_insert_with(|| { // 全局初始化
            info!("runtime init");
            Executor::new(&mut ())
        })
    };

    let spawner = runtime.spawner();

    spawner.spawn(run(1000, || /* 打印 */)).unwrap();
    spawner.spawn(run(500, || /* 打印 */).unwrap();

    unsafe { runtime.poll() };
}
```

为了简要展示打印信息，这里以一个异步打印任务为例：

```text
[ INFO] runtime init
[ INFO] [now=13468888] [embassy_runtime] spawn a timer task: they will print in 1 sec
[ INFO] [now=13575455] set_timer for timestamp=23563440

... omit output from unrelated user code

[user sapce] [ch3b_sleep] Start now=1504ms
[user space] [ch3b_sleep1] Starts now=1514ms

... omit output from unrelated user code

[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=23609191] [embassy_runtime] spawn a timer task: they will print in 1 sec
[now=23693536] [task 1 (0) done] tick for 1 sec
[ INFO] [now=23743502] set_timer for timestamp=33743074
[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=33790778] [embassy_runtime] spawn a timer task: they will print in 1 sec
[now=33855220] [task 1 (1) done] tick for 1 sec
[ INFO] [now=33888388] set_timer for timestamp=43887940

[user space] [ch3b_sleep1] now=3520ms after sleeping 100 ticks, delta = 2006ms!
[user space] [ch3b_sleep1]Test sleep1 passed! now=3526ms

[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=43934302] [embassy_runtime] spawn a timer task: they will print in 1 sec
[now=43995955] [task 1 (2) done] tick for 1 sec
[ INFO] [now=44026432] set_timer for timestamp=54026064

[user sapce] [ch3b_sleep] Test sleep OK! now=4504ms
[kernel] Panicked at src/task/mod.rs:135 All applications completed!
```

这个日志报告的执行过程可表示为：

| 时间轴<br>(自开机以来) | kernel<br>(定时打印)                       | ch3b_sleep<br>(sleep 3 秒) | ch3b_sleep1<br>(sleep 2 秒) |
|:----------------------:|--------------------------------------------|----------------------------|-----------------------------|
|          1.3s          | 内核初始化，设置下次打印为 1s 后           | 未执行                     | 未执行                      |
|          1.5s          | -                                          | 开始执行 sleep             | 开始执行                    |
|          2.3s          | 陷入时钟中断，并打印；设置下次打印为 1s 后 | -                          | -                           |
|          3.3s          | 陷入时钟中断，并打印；设置下次打印为 1s 后 | -                          | -                           |
|          3.5s          | -                                          | -                          | sleep 结束                  |
|          4.3s          | 陷入时钟中断，并打印；设置下次打印为 1s 后 | -                          | -                           |
|          4.5s          | -                                          | sleep 结束，内核退出       | -                           |


<details>

<summary>两个定时任务（1 秒和 0.5 秒后打印）的执行情况：点击 展开/折叠 输出结果</summary>

```text
[ INFO] runtime init
[ INFO] [now=8963079] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[ INFO] [now=9074716] set_timer for timestamp=14063168

... omit output from unrelated user code

[user sapce] [ch3b_sleep] Start now=1059ms
[user space] [ch3b_sleep1] Starts now=1063ms

... omit output from unrelated user code

[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=14100964] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[now=14180971] [task 2 (0) done] tick for 0.5 sec
[ INFO] [now=14217068] set_timer for timestamp=19072535
[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=19110271] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[now=19180360] [task 1 (1) done] tick for 1 sec
[ INFO] [now=19214358] set_timer for timestamp=19216534
[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=19306211] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[now=19343169] [task 2 (2) done] tick for 0.5 sec
[ INFO] [now=19362740] set_timer for timestamp=24213682
[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=24252478] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[now=24324734] [task 1 (3) done] tick for 1 sec
[now=24355001] [task 2 (4) done] tick for 0.5 sec
[now=24388689] [task 2 (5) done] tick for 0.5 sec
[ INFO] [now=24421088] set_timer for timestamp=29214028
[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=29275492] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[now=29345915] [task 1 (6) done] tick for 1 sec
[now=29382478] [task 1 (7) done] tick for 1 sec
[now=29413583] [task 2 (8) done] tick for 0.5 sec
[ INFO] [now=29442517] set_timer for timestamp=34381657

[user space] [ch3b_sleep1] now=3067ms after sleeping 100 ticks, delta = 2004ms!
[user space] [ch3b_sleep1]Test sleep1 passed! now=3072ms

[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=34417918] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[now=34488639] [task 1 (9) done] tick for 1 sec
[now=34519730] [task 2 (10) done] tick for 0.5 sec
[ INFO] [now=34551988] set_timer for timestamp=39381982
[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=39420027] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[now=39492751] [task 1 (11) done] tick for 1 sec
[ INFO] [now=39524484] set_timer for timestamp=39551507
[ WARN] Interrupt::SupervisorTimer
[ INFO] [now=39584847] [embassy_runtime] spawn two timer tasks: they will print in 0.5 sec and 1 sec
[now=39626547] [task 2 (12) done] tick for 0.5 sec
[ INFO] [now=39645440] set_timer for timestamp=44523987

[user sapce] [ch3b_sleep] Test sleep OK! now=4059ms
[kernel] Panicked at src/task/mod.rs:135 All applications completed!
```

</details>

# 一些重要的细节

## 调整时钟频率

rCore 中将 qemu 的时钟频率记录为 12_500_000 Hz，但这里采用 10_000_000 Hz。这个调整体现在 
embassy-time 启用 tick-hz-10_000_000 feature，以及将内核代码中 CLOCK_FREQ 常量修改为 10_000_000。

这个修改的目的是为了更好地观察计数器的值，`TimerDriver::now` 以 tick 作为时间单位而不是换算过的时间单位，那么从
18M tick 计数开始 1 “秒”，只需观察 tick 计数在 28M 处的时间。

这带来的最大影响，只是内核中的 1 秒钟比现实中的 1 秒钟更快，因为我们没有改动硬件上的时钟频率，所以依然是
12.5 MHz 走完 1 秒，而现在 10 MHz 视为 1 秒，而实际并不花费 1 秒。

这个差异对我们的实验并不重要，内核态和用户态的时间 tick 数是统一的，只是换算成的毫秒或者秒与实际时间有些差异而已。

你也可以不调整这个，但存在两个问题：
* embassy-time 不具备 12.5MHz 的 feature，所以需要去调查如何设置它（我没有兴趣调查这个）
* 如果 embassy-time 的时钟频率设置和 rCore 里的不一致，那么 `Timer` 相关的 API 计算的 ticks 数会不准确

## 简化了轮询代码

我们只在每次定时器中断时，仅调用一次 `Executor::poll`，也就是把所有异步任务推进 1 步。

推进 1 步，是指把任务执行到下个 Pending 状态（如果有的话）。

你可以把异步任务推进 n 步，那么只需改成调用 `Executor::poll` n 次。

但我们这里只考虑非常简单的定时任务，多次调用 `Executor::poll`，它们也必须在到期时间之后才能继续（甚至不会被放进执行任务栈），因此调用一次
`Executor::poll` 既可以保持简单，又能让它们在到期后执行下去。

## 简化了定时任务

体现在
* 定时任务是简单的、一次性的：每次时钟中断固定设置 1 秒和 0.5 秒的定时
* 设定的时间比原来 rCore 设定的定时器时间长很多：rCore 设定的时间片为一秒钟打断 100 次（`set_timer(get_time() + CLOCK_FREQ / TICKS_PER_SEC)`），
  但目前没有那样做，因为这会中断太多次而让输出看起来杂乱 —— 恢复 rCore 那种做法是很容易做到的，只需要设置一个相同时长的异步任务就行。不过，这也导致了
  那些用户态很快执行完的程序是按顺序执行的（因为它们还没在被打断之前就已经结束运行了）。为此，我将用户态的 `ch3_sleep` 和 `ch3_sleep1` 两个测例变成了
  基础测例（只需修改它们的文件名，以及需要在内核实现相关的系统调用），这样，就能在用户程序 sleep 期间，观察到内核态的异步定时任务执行过程。
* 定时任务采用了最简单的、自动可重用的静态任务池： embassy 在任务上做了一个假设和规定，即使任务完成，不会（并且禁止）收回其内存资源（因为底层 API 
  `TaskStorage::spawn(&'static self, ...)` 中包含一个 `'static` 生命周期，收回内存，会打破这个编译器的 invariant，导致 UB）。
  `#[embassy_executor::task]` 实际具有一些限制，如果有人对此有兴趣了解，或者想知道如何使用低级的 `TaskStorage` API 做更复杂的事情（比如动态任务、手动重用任务），见 [我的笔记]。

[我的笔记]: https://zjp-cn.github.io/os-notes/embassy-task.html

## 先在 ch1 上应用

向老师给出了特别重要的建议，让我们将问题拆分成三个步骤，每一步做到位就一定能成功：
1. 在裸机上，通过 embassy 设置定时，确保功能正常；
2. 将 rCore 的时钟中断处理替换成 embassy 能正常工作的代码；
3. 弄清楚 rCore 和 embassy 的边界。

ch1 相当于一个 riscv 裸机环境，而 ch3 是一个初步的操作系统。

我最先在 ch1 上进行实验（[代码在 ch1-embassy 分支上][ch1-embassy]），成功后才放置到 ch3 上面。

[ch1-embassy]: https://gitee.com/ZIP97/rCore-tutorial-code-2024S-embassy/blob/ch1-embassy/os/src/main.rs

ch1-embassy 的代码目前有点乱，核心改动在于：
* 建立与 ch3 类似的 embassy 定时器驱动和运行时，几乎与上面的代码一模一样；
* 异步任务永远在定时打印，而不是一次性的；
* `Executor::poll` 是多次调用的（放置在循环内）；
* 每次调用 `Executor::poll` 后，通过 wfi 指令让 CPU 休眠，并搭配计时器中断，从而唤醒 CPU、陷入中断处理，从而减少 CPU 使用，并且避免了无意义的 set_alarm 调用；
* 中断处理函数 `handle_timer_trap` 并不使用汇编，因为没有用户态程序，我们甚至没有保存中断的上下文（不确定这是不是正确的，但打印结果已经是我们想要的）；
* 记得开启时钟中断相关的状态，即调用 `sstatus::set_sie()` 和 `sie::set_stimer()`。有一个我们调试很久也无法解决的问题，sie CSR 在 S 态出现中断后，进入 
  ISR，机器会自动对它清零，从而不会出现中断嵌套；但我们需要在合适的时候使能 sie，通过开启时钟中断响应继续进入 ISR。我试过在某些地方放置 
  set_sie，观察到行为良好，但在其他地方出现莫名其妙的 bug（不限于打印意外字符而进入死循环、奇怪的指令错误等等）。

# 可能改进的地方

* 现在只考虑了定时的异步任务，而 embassy 实际支持一般意义上的异步任务，那么我们希望在内核中除定时任务之外，支持什么样的异步任务呢？换句话说，如何拓展异步运行时到整个内核？
  * 在第 3 章，rCore 最主要的任务就是通过时间片轮换来并发地执行用户态程序，这似乎已经与异步紧密联系，有可能利用 embassy 来调度用户态程序吗（任务的暂停点就是时间片结束）？
* 考虑支持需要多次推进才能完成的更复杂的异步任务。但这会带来一个问题，此时如何调用 `Executor::poll` 才更合理？显然当前一次时钟中断只调用它一次，
  那么所有任务必须等到下次时钟中断才能推进 1 步，这不足以让非定时的任务尽快完成。

# 致谢

感谢向老师在这 6 周时间里倾囊相授，尤其对我充满了耐心、热情和鼓励。与您所交流的一切，远远大于我在训练营里学习的所有知识，也是我所得到的最具价值的收获。您是我遇见的最好的老师！

感谢陶要仲同学将异步运行时放置到时间中断处理函数里面，这是完成向老师所提的第二个步骤的最重要的一环；也谢谢你在最后一周、连续三个晚上倾听我喋喋不休，最终我们愉快地合作成功。
