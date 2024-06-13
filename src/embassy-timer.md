# `embassy_time_driver::Driver`

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


