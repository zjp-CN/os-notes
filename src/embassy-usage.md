# embassy-usage

## `raw::Executor` 和 `__pender`

```rust
#[macro_use]
extern crate log;

use embassy_futures::yield_now;
use std::{cell::Cell, rc::Rc};

#[embassy_executor::task]
async fn run1() {
    info!("run1 starts");
    for i in 0..3 {
        info!("run1 yield_now");
        yield_now().await;
        info!("[{i}] run1");
    }
    info!("run1 ends");
}

#[embassy_executor::task]
async fn run2() {
    info!("run2 starts");
    for i in 0..3 {
        info!("run2 yield_now");
        yield_now().await;
        warn!("[{i}] run2");
    }
    info!("run2 ends");
}

fn main() {
    # debug!("main starts");
    env_logger::builder().format_timestamp(None).format_target(false).init();
    let context = ExecutorCxt::default();
    let ctx = Box::into_raw(Box::new(context.clone()));
    let executor = Box::leak(Box::new(embassy_executor::raw::Executor::new(ctx.cast())));
    # debug!("initialized: logger, executor, context");
    let spawner = executor.spawner();
    # debug!("before spawn");
    spawner.spawn(run1()).unwrap();
    # debug!("after spawn1");
    spawner.spawn(run2()).unwrap();
    # debug!("after spawn2");
    while context.pend.take() {
        # debug!("polling due to pender");
        unsafe { executor.poll() }
    }
    # debug!("main ends");
}

#[derive(Default, Clone)]
struct ExecutorCxt {
    pend: Rc<Cell<bool>>,
}

#[export_name = "__pender"]
fn pender(context: *mut ()) {
    // schedule `poll()` to be called
    unsafe { &*context.cast::<ExecutorCxt>() }.pend.set(true);
    debug!("pender and notify");
}
```

<details>

<summary>点击“展开/收起” <code>RUST_LOG=debug cargo r</code> 输出</summary>

注意：
* main 函数内的 `debug!` 被隐藏，点击上面代码块右上角按钮显示
* `[embassy-executor]` 的日志来自我修改过的 embassy 子模块（具体 [提交在这][logging embassy]）

[logging embassy]: https://gitee.com/ZIP97/embassy/commit/86679b5723881bf03d9983d0e5bb8e78e387aa98

```text
[DEBUG] initialized: logger, executor, context
[DEBUG] before spawn
[DEBUG] [embassy-executor] (enqueue) prepend a task
[DEBUG] [embassy-executor] (run_queue) was empty queue: enqueue the given task and call pend
[DEBUG] pender and notify
[DEBUG] after spawn1
[DEBUG] [embassy-executor] (enqueue) prepend a task
[DEBUG] after spawn2
[DEBUG] polling due to pender
[DEBUG] [embassy-executor] empty the queue
[DEBUG] [embassy-executor] handle task 0
[INFO ] [embassy-executor] (dequeue_all): poll a task
[DEBUG] [embassy-executor] (state) (run_dequeue): unmark run-queued
[INFO ] run2 starts
[INFO ] run2 yield_now
[DEBUG] [embassy-executor] (state) spawn but not queued: wake_task run_enqueue
[DEBUG] [embassy-executor] (enqueue) prepend a task
[DEBUG] [embassy-executor] (run_queue) was empty queue: enqueue the given task and call pend
[DEBUG] pender and notify
[DEBUG] [embassy-executor] handle task 1
[INFO ] [embassy-executor] (dequeue_all): poll a task
[DEBUG] [embassy-executor] (state) (run_dequeue): unmark run-queued
[INFO ] run1 starts
[INFO ] run1 yield_now
[DEBUG] [embassy-executor] (state) spawn but not queued: wake_task run_enqueue
[DEBUG] [embassy-executor] (enqueue) prepend a task
[DEBUG] polling due to pender
[DEBUG] [embassy-executor] empty the queue
[DEBUG] [embassy-executor] handle task 0
[INFO ] [embassy-executor] (dequeue_all): poll a task
[DEBUG] [embassy-executor] (state) (run_dequeue): unmark run-queued
[INFO ] [0] run1
[INFO ] run1 yield_now
[DEBUG] [embassy-executor] (state) spawn but not queued: wake_task run_enqueue
[DEBUG] [embassy-executor] (enqueue) prepend a task
[DEBUG] [embassy-executor] (run_queue) was empty queue: enqueue the given task and call pend
[DEBUG] pender and notify
[DEBUG] [embassy-executor] handle task 1
[INFO ] [embassy-executor] (dequeue_all): poll a task
[DEBUG] [embassy-executor] (state) (run_dequeue): unmark run-queued
[WARN ] [0] run2
[INFO ] run2 yield_now
[DEBUG] [embassy-executor] (state) spawn but not queued: wake_task run_enqueue
[DEBUG] [embassy-executor] (enqueue) prepend a task
[DEBUG] polling due to pender
[DEBUG] [embassy-executor] empty the queue
[DEBUG] [embassy-executor] handle task 0
[INFO ] [embassy-executor] (dequeue_all): poll a task
[DEBUG] [embassy-executor] (state) (run_dequeue): unmark run-queued
[WARN ] [1] run2
[INFO ] run2 yield_now
[DEBUG] [embassy-executor] (state) spawn but not queued: wake_task run_enqueue
[DEBUG] [embassy-executor] (enqueue) prepend a task
[DEBUG] [embassy-executor] (run_queue) was empty queue: enqueue the given task and call pend
[DEBUG] pender and notify
[DEBUG] [embassy-executor] handle task 1
[INFO ] [embassy-executor] (dequeue_all): poll a task
[DEBUG] [embassy-executor] (state) (run_dequeue): unmark run-queued
[INFO ] [1] run1
[INFO ] run1 yield_now
[DEBUG] [embassy-executor] (state) spawn but not queued: wake_task run_enqueue
[DEBUG] [embassy-executor] (enqueue) prepend a task
[DEBUG] polling due to pender
[DEBUG] [embassy-executor] empty the queue
[DEBUG] [embassy-executor] handle task 0
[INFO ] [embassy-executor] (dequeue_all): poll a task
[DEBUG] [embassy-executor] (state) (run_dequeue): unmark run-queued
[INFO ] [2] run1
[INFO ] run1 ends
[DEBUG] [embassy-executor] despawn
[DEBUG] [embassy-executor] handle task 1
[INFO ] [embassy-executor] (dequeue_all): poll a task
[DEBUG] [embassy-executor] (state) (run_dequeue): unmark run-queued
[WARN ] [2] run2
[INFO ] run2 ends
[DEBUG] [embassy-executor] despawn
[DEBUG] main ends
```

</details>

## 任务的执行顺序

通过调高日志等级 `RUST_LOG=info cargo r`，可以观察到 `embassy-executor` 执行这两个任务的顺序为

<details>

<summary><code>2 - 1 - 1 - 2 - 2 - 1 (结束) - 2 (结束)</code> 点击“展开/收起” info 级别的日志</summary>


```text
[INFO ] [embassy-executor] (dequeue_all): poll a task
[INFO ] run2 starts
[INFO ] run2 yield_now
[INFO ] [embassy-executor] (dequeue_all): poll a task
[INFO ] run1 starts
[INFO ] run1 yield_now
[INFO ] [embassy-executor] (dequeue_all): poll a task
[INFO ] [0] run1
[INFO ] run1 yield_now
[INFO ] [embassy-executor] (dequeue_all): poll a task
[WARN ] [0] run2
[INFO ] run2 yield_now
[INFO ] [embassy-executor] (dequeue_all): poll a task
[WARN ] [1] run2
[INFO ] run2 yield_now
[INFO ] [embassy-executor] (dequeue_all): poll a task
[INFO ] [1] run1
[INFO ] run1 yield_now
[INFO ] [embassy-executor] (dequeue_all): poll a task
[INFO ] [2] run1
[INFO ] run1 ends
[INFO ] [embassy-executor] (dequeue_all): poll a task
[WARN ] [2] run2
[INFO ] run2 ends
```

</details>



```rust
// src: https://github.com/embassy-rs/embassy/blob/6bbb870bfade23e814169eb48e42e8bc55d9ff8f/embassy-executor/src/raw/run_queue_atomics.rs#L70
impl RunQueue {
    /// Empty the queue, then call `on_task` for each task that was in the queue.
    /// NOTE: It is OK for `on_task` to enqueue more tasks. In this case they're left in the queue
    /// and will be processed by the *next* call to `dequeue_all`, *not* the current one.
    pub(crate) fn dequeue_all(&self, on_task: impl Fn(TaskRef)) {
        // Atomically empty the queue.
        let ptr = self.head.swap(ptr::null_mut(), Ordering::AcqRel);

        // safety: the pointer is either null or valid
        let mut next = unsafe { NonNull::new(ptr).map(|ptr| TaskRef::from_ptr(ptr.as_ptr())) };

        // Iterate the linked list of tasks that were previously in the queue.
        while let Some(task) = next {
            // If the task re-enqueues itself, the `next` pointer will get overwritten.
            // Therefore, first read the next pointer, and only then process the task.
            // safety: there are no concurrent accesses to `next`
            next = unsafe { task.header().run_queue_item.next.get() };

            on_task(task);
        }
    }
}

// src: https://github.com/embassy-rs/embassy/blob/6bbb870bfade23e814169eb48e42e8bc55d9ff8f/embassy-executor/src/raw/mod.rs#L386
impl SyncExecutor {
    // 这不是完整代码，只展示传递给 dequeue_all 的回调函数
    pub(crate) unsafe fn poll(&'static self) {
        loop {
            self.run_queue.dequeue_all(|p| {
                let task = p.header();

                #[cfg(feature = "integrated-timers")]
                task.expires_at.set(u64::MAX);
                    return;
                }

                // Run the task
                task.poll_fn.get().unwrap_unchecked()(p);

                // Enqueue or update into timer_queue
                #[cfg(feature = "integrated-timers")]
                self.timer_queue.update(p);
            });
        }
    }
}
```
