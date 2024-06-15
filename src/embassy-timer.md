# `embassy_time_driver::Driver`

在 embassy 中，计时器的核心抽象是 Driver 接口：

```rust
pub trait Driver: Send + Sync + 'static {
    fn now(&self) -> u64;

    unsafe fn allocate_alarm(&self) -> Option<AlarmHandle>;

    fn set_alarm_callback(
        &self,
        alarm: AlarmHandle,
        callback: fn(_: *mut ()),
        ctx: *mut ()
    );

    fn set_alarm(&self, alarm: AlarmHandle, timestamp: u64) -> bool;
}
```

结合 embassy 一些实现代码，我发现 `Driver` trait 的类型大多有以下行为：
* `now` 函数提供 tick 级别的、自开机以来的时间（不一定作为字段存储在类型上，因为可以直接读取状态寄存器来获取时间）
* `allocate_alarm` 函数提供 alarm 分配逻辑：
  * alarm 应该有自己的数据结构（比如 AlarmState），存储来自执行器设置的回调函数和执行器实例
  * alarm 的功能：适时执行回调函数
  * 分配 alarm 的数量通常是有上限的，该数量尤其是编译时已知的，比如 `[AlarmState; N]`，其中索引为 AlarmHandle 
  * AlarmHandle 实际上是一个整数编号的包装器类型，所以分配一个 alarm，就是分配一个索引/编号（当然，也可能包含一些设置 AlarmState 的逻辑）
* `set_alarm_callback` 函数其实就是对第 n 个 alarm 在运行时进行初始化，通常由执行器设置
* `set_alarm` 函数通过告知第 n 个 alram，以及一个给定的 tick 时刻来安排执行回调函数
  * 当这个给定的时刻处于将来，那么它返回 true，以非同步方式安排回调函数执行，这意味着不要在 set_alarm 函数内直接运行回调函数！
  * 当这个给定的时刻已经过去，那么它返回 false，无需安排回调函数执行
  * `embassy-executor` 开启 `integrated-timers` feature 之后，一旦 set_alarm 返回 true，那么结束一轮 poll；如果 set_alarm 
    一直返回 false，那么将这轮 poll 会一直持续下去

这个 [回调函数] 目前仅仅是调用 `__pender` 函数，相应的代码如下：

[回调函数]: https://github.com/embassy-rs/embassy/blob/74739997bd70d3c23b5c58d25aa5c9ba4db55f35/embassy-executor/src/raw/mod.rs#L359

```rust
// 每个编译目标提供：
// * embassy 在 arch* feature 上提供默认的 __pender
// * 如果自己提供，不要开启 embassy 任何 arch 开头的 feature
#[export_name = "__pender"]
fn __pender(context: *mut ()) { ... } // context 实际上是 *mut SyncExecutor

impl SyncExecutor { // Executor 的内部结构
    #[cfg(feature = "integrated-timers")]
    fn alarm_callback(ctx: *mut ()) {
        let this: &Self = unsafe { &*(ctx as *const Self) };
        this.pender.pend(); // 最终调用 __pender
    }

    pub(crate) unsafe fn poll(&'static self) {
        #[cfg(feature = "integrated-timers")]
        // 由执行器注册回调函数 (__pender)
        embassy_time_driver::set_alarm_callback(self.alarm, Self::alarm_callback, self as *const _ as *mut ());
        ...
        loop {
            ...
            #[cfg(feature = "integrated-timers")]
            {
                // If this is already in the past, set_alarm might return false
                // In that case do another poll loop iteration.
                let next_expiration = self.timer_queue.next_expiration();
                if embassy_time_driver::set_alarm(self.alarm, next_expiration) {
                    // 当 set_alarm 返回 true，结束这轮 poll，安排执行 __pender
                    break;
                }
            }
        }
        ...
    }
}
```

## `now`

```rust
fn now(&self) -> u64
```

当前的时间戳，用 tick 计算；必须保证：
* 单调增加：调用的结果总是比之前调用的结果更大或者相等（时间不能回退）
* 不能溢出：可以运行足够长的时间

## `allocate_alarm`

```rust
unsafe fn allocate_alarm(&self) -> Option<AlarmHandle>
```

试图分配一个“警报器” (alarm, 用来在某个时间到了调用回调函数)。

alarm 应该携带一个回调函数和上下文指针：
* 初始化 alarm 的时候，没有 callback，ctx 为 null
* executor 会通过 `set_alarm_callback`，给这个 alram 设置回调和上下文。
  safty: 在设置回调之前触发 alarm，是 UB 行为。

如果 alarm 用完了，那么返回 None。

## `set_alarm_callback`

```rust
fn set_alarm_callback(
    &self,
    alarm: AlarmHandle,
    callback: fn(_: *mut ()),
    ctx: *mut ()
)
```
给一个 alarm 设置回调函数和上下文。

这个回调函数：
* 应在触发 alarm 时调用
* 参数是 ctx
* 可能从任何上下文调用（中断、或者 thread mode）

## `set_alarm`

```rust
fn set_alarm(&self, alarm: AlarmHandle, timestamp: u64) -> bool
```

如果当前时间戳达到这个给定的时间戳，应调用回调函数。

返回值
* true 表示设置/触发 alarm，应尽快安排 **异步** 调用 alarm 的回调函数：此函数绝不能同步调用回调函数；当前时间 <= 给定的时间
  * 如果给定的时间马上就要发生，并且设置 alarm 后，这个时间滑入过去，情况有些复杂
* false 表示不设置 alarm：当前时间 > 给定时间

当调用回调函数时，必须保证 now() 返回的时间 >= 给定时间。

每个 AlarmHandle 一次只能设置一个 alarm：如果之前设置了 alarm，后面设置的 alarm 应该覆盖之前设置的 alarm。

# 实现例子

实现 `__pender` 函数的例子：[embassy-executor/src/arch](https://github.com/embassy-rs/embassy/tree/74739997bd70d3c23b5c58d25aa5c9ba4db55f35/embassy-executor/src/arch) 。

实现 Driver trait 的例子：

* [embassy-time/src/driver_std.rs](https://github.com/embassy-rs/embassy/blob/74739997bd70d3c23b5c58d25aa5c9ba4db55f35/embassy-time/src/driver_std.rs#L115)
* [embassy-time/src/driver_mock.rs](https://github.com/embassy-rs/embassy/blob/74739997bd70d3c23b5c58d25aa5c9ba4db55f35/embassy-time/src/driver_mock.rs#L81)
* [embassy-stm32/src/time_driver.rs](https://github.com/embassy-rs/embassy/blob/74739997bd70d3c23b5c58d25aa5c9ba4db55f35/embassy-stm32/src/time_driver.rs#L518)

