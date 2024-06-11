# 《200 行代码讲透 Rust Futures》

## 背景/唠嗑

《[200 行代码讲透 Rust Futures](https://stevenbai.top/rust/futures_explained_in_200_lines_of_rust/) 》
已经是我三年前就找到的文章，当时我还翻译过这个外国作者的 Rust 异步系列的另一本书籍
《[The Node Experiment - Exploring Async Basics with Rust](https://github.com/Rust-Chinese-Translation/exploring-async-basics-with-rust_zh)》
（这是个半成品，因为讲的太过啰嗦，翻译了一半还没看到重点）。

只是，那个时候我对 async Rust 不熟。Rust 和 async Rust 完全是两个世界，这已经是 Rust 社区的共识，所有人都认可
async Rust 给 Rust 带来巨大的复杂性和极高的门槛。对我来说，我学习 Rust 整理的[资料][m]中，至少 1/4 与异步 Rust 有关，
在我翻译的零碎 Rust [文章][a]中，至少 1/3 是 async Rust。

[m]: https://www.yuque.com/zhoujiping/programming/rust-materials

[a]: https://zjp-cn.github.io/translation/

小插曲 0：作为一个每日关注 Rust 社区动态的观察者，我知道原外国作者已经把 Rust 异步系列的电子书和仓库链接都删除了，
然后几个月前正式发布了新书《[Asynchronous Programming in Rust: Learn asynchronous programming by building
working examples of futures, green threads, and runtimes][cfsamson-book]》（[原帖][cfsamson]）

[cfsamson-book]: https://www.amazon.com/Asynchronous-Programming-Rust-asynchronous-programming/dp/1805128132

[cfsamson]: https://www.reddit.com/r/rust/comments/1amlro1/new_rust_book_asynchronous_programming_in_rust_is/

小插曲 1：在这篇文章中提及的“stejpang 的文章”，也消失在互联网上了，stejpang 曾经是 Rust 多个重要异步生态基础库的作者
—— 我关注到这个情况的时候，互联网上已经鲜有对此的讨论 —— 但 ta 的消失是 Rust 社区都知道的事情。

小插曲 2：该文章还提及了 [without.boats](https://without.boats/)，他是 Rust 异步设计中的一个重要人物，我学习 Rust 
的时候，他已经渐渐退出了对 Rust 的贡献。据说是出于他的工作原因，他不太被允许对开源项目做具体贡献。
但至今，依然可以看见他在关注异步 Rust，并且经常发布优质的异步 Rust 博客；在 zulichat/github 之类的讨论中，总是附带“非贡献”免责声明。

## 文章总结

### 其他并发方式

操作系统级别的线程：
* 优点：通常是多任务的正确解决方案；相对简单易用；多核机器上，直接利用它得到并行
* 缺点：任务数量太大时，切换线程的成本会高于其他并发方式（比如系统调用的成本、堆栈成本、内存占用成本）

用户级别的线程（绿色线程）：
* 优点：切换上下文的成本低于操作系统级别的线程
* 缺点：
  * 栈的大小随任务数量而增长（栈拷贝等问题）
  * 不是零成本抽象
  * 很难在支持多平台上正确实现
* 应用： goroutine

事件循环：通过注册一系列事件，在所有事件上循环迭代，处理已经通知循环的待处理的事件。当所有触发的事件处理完毕，事件循环再开始，然后处理新的触发事件。
* 优点：适合单线程模型、异步、非阻塞 IO 
* 缺点：回调地狱（回调层级太多导致代码难以阅读和维护）、不适合 CPU 密集型任务
* 应用：libuv（node.js、neovim）、Rust 的 mio（tokio）

Future/Promise + async/await 语法：
* 优点：通过把嵌套调用转化成链式调用、把异步逻辑分解成函数或者模块，在语法上看起来像同步调用
* 缺点：不适合 CPU 密集型任务

# Rust 的 `asm!` 语法

* [RFC 1458: `global_asm!`](https://rust-lang.github.io/rfcs/1548-global-asm.html)：模块级别的汇编
* [RFC 2873: `asm!`](https://rust-lang.github.io/rfcs/2873-inline-asm.html)：内联汇编，将手写的汇编嵌入编译器生成的汇编输出中
  * 官方示例：[Rust By Example: `asm!`](https://doc.rust-lang.org/stable/rust-by-example/unsafe/asm.html)
  * `global_asm!` 与 `asm!` 识别一样的语法，前者可以写在模块内，后者写在函数内

## 基础写法

```rust
// 注意：编写汇编是 unsafe 操作
use core::arch::asm;

// 基本写法：汇编指令
asm!("nop");

// 类似 format! 宏的变量插值写法

// * 通常需要指定寄存器，在下面指定了 reg，表示编译器会选择一个通用寄存器，
//   当然也可以指定特定的寄存器，比如 `in("eax")`
// * `out(reg) x` 表示对这个寄存器进行输出操作，即从 reg 寄存器中写出到变量 x
let x: u64;
asm!("mov {}, 5", out(reg) x); // mov 指令写入立即数 5 到寄存器，然后寄存器写出到变量 x
assert_eq!(x, 5);

// mov dst, src 指令用于将数据从源操作数传送到目标操作数。以下代码经历几个步骤：
// 1. 源寄存器 {1}：对它进行写入操作，把变量 i 的值写入 {1} 寄存器，此时 {1} 内的值为 3
// 2. 执行 mov 指令，此时目标寄存器 {0} 内的值为 3
// 4. 执行 add 指令，{0} 内的值 +5 变成了 8
// 5. {0} 写出到 o，最终变量 o 的值为 8
let i: u64 = 3;
let o: u64;
asm!(
    "mov {0}, {1}",
    "add {0}, 5",
    out(reg) o,
    in(reg) i,
);
assert_eq!(o, 8);

// 上面的写法可以简化如下写法：`inout(reg) x`
// 先把 x 的值写入到寄存器，然后执行 add，最后从寄存器写出到 x；
// 与上面有一点不同，inout 会确保写入和写出的寄存器为同一个。
let mut x: u64 = 3;
asm!("add {0}, 5", inout(reg) x); // x -> reg; instruction; reg -> x
assert_eq!(x, 8);

// 与上面的不同指定不同的写入和写出变量：从 x 写入到寄存器，然后执行 add，最后从寄存器写出到 y
let x: u64 = 3;
let y: u64;
asm!("add {0}, 5", inout(reg) x => y); // x -> reg; instruction; reg -> y
assert_eq!(y, 8);
```

## Late output operands

使用 late 一类的操作，编译器会尽可能优化到使用尽可能最少的寄存器，也就是说，额外寄存器可能被优化掉。


```rust
let mut a: u64 = 4;
let b: u64 = 4;
let c: u64 = 4;
// 在优化的情况下：
// * 由于 b 和 c 相等，指定的 reg 寄存器可能为同一个；
// * 又由于使用 inlateout 操作，c 和 a 的寄存器可能为同一个；最终导致 a b c 共用一个寄存器
asm!(
    "add {0}, {1}", // a -> {0}; add {0}, {0} 此时 a (= 4+4) = 8 
    "add {0}, {2}", // add {0}, {0}; {0} -> a 此时 a (= 8+8) = 16
    inlateout(reg) a,
    in(reg) b,
    in(reg) c,
);
assert_eq!(a, 12); // assertion fail: unexpected
```

如果这种优化需要避免，则不应该使用 late 操作，而是直接读取寄存器

```rust
let mut a: u64 = 4;
let b: u64 = 4;
let c: u64 = 4;
asm!(
    "add {0}, {1}", // b -> {1}; a -> {0}; add; {0} -> a 此时 a (= 4+4) = 8 
    "add {0}, {2}", // c -> {2}; a -> {0}; add; {0} -> a 此时 a (= 4+8) = 12
    inout(reg) a,
    in(reg) b,
    in(reg) c, 
);
// 即使 {2} 与 {1} 为同一个寄存器，也不影响结果，因为 c 和 a 不再是
assert_eq!(a, 12); // expected: good
```

## 显式指定寄存器

```rust
asm!("out 0x64, eax", in("eax") cmd);

fn mul(a: u64, b: u64) -> u128 {
    let lo: u64;
    let hi: u64;

    // a -> reg; b -> rax; rax -> lo; rad -> hi
    unsafe {
        asm!(
            // The x86 mul instruction takes rax as an implicit input and writes
            // the 128-bit result of the multiplication to rax:rdx.
            "mul {}", 
            in(reg) a,
            // 注意：显式指定的寄存器必须放置在其他操作类型之后
            inlateout("rax") b => lo,
            lateout("rdx") hi
        );
    }

    ((hi as u128) << 64) + lo as u128
}
```



其他资料：
* [协程异步操作系统-学习记录二](https://blog.seadraw.top/2023/11/18/%E5%8D%8F%E7%A8%8B%E5%BC%82%E6%AD%A5%E6%93%8D%E4%BD%9C%E7%B3%BB%E7%BB%9F%E5%AD%A6%E4%B9%A0%E8%AE%B0%E5%BD%95%E4%BA%8C/)

## Intel vs AT&T 语法

对于 x86-64， `asm!` 默认使用 Intel 语法，因此不要在asm 字符串内使用 `.intel_syntax` 或者 `.att_syntax`。
切换到 AT&T 语法，只需添加一个 `att_syntax` 设置， 即 `asm!("...", other, params, options(att_syntax))`。

在 GCC 上，这会造成混乱，因为 GCC 默认采用 AT&T 语法。（GCC 可通过 `-masm=intel` 参数来生成 Intel 语法的汇编）

此外，GDB 默认以 AT&T 语法显式汇编，所以需要使用 `set disassembly-flavor intel` 命令来显式 Intel 语法。
这个转换不会对已经执行和展示的指令生效，必须执行下条指令，才可以看到新语法格式。
不过，在 GDB 中显式的 Intel 语法为 `mov QWORD PTR [rsi+0x38],rdi`，它比实际写的 `mov [rsi+0x38], rdi` 要啰嗦多了：）

AT&T 语法 `mov %rdi, 0x38(%rsi)` 对应的 Intel 语法为 `mov [rsi+0x38], rdi` Intel 语法。
嗯，注意到了吗，它们在源操作数和目标操作数上是相反的！

Intel 语法和 AT&T 语法的主要区别在于：

|              | Intel 语法                                         | AT&T 语法                                      |
|--------------|----------------------------------------------------|------------------------------------------------|
| 操作数顺序   | “目标，源”，<br>即先写目标操作数，后写源操作数     | “源，目标”，<br>即先写源操作数，后写目标操作数 |
| 内存引用表示 | 使用方括号，例如 `[eax]`                           | 使用圆括号，例如 `(%eax)`                      |
| 相对寻址表示 | 偏移量在寄存器后，例如 `[eax+0x10]`[^offset-intel] | 偏移量在寄存器前，例如 `0x10(%eax)`            |
| 寄存器前缀   | 无前缀                                             | 寄存器名称前使用 `%` 前缀                      |
| 立即数表示   | 无前缀                                             | 立即数前使用 `$` 前缀                          |
| 指令前缀     | 无前缀                                             | 指令名前使用 `.` 前缀                          |


[^offset-intel]: `asm!` 还支持某些非标准的 Intel 语法：`mov rdi, 0x38[rsi]`（标准写法为 `mov rdi, [rsi+0x38]`
或者 `mov rdi, qword ptr [rsi + 0x38]`）。

整体来说，`asm!` 采用 GNU assembler (GAS) 的汇编语法，具体的语法是特定于目标架构的。在 x86 上，使用 `.intel_syntax noprefix`
模式；在 ARM 上，使用 `.syntax unified` 模式。更多细节，需要去查阅上述我列的 RFC。


# 《通过迭代 WebServer 逐步深入 Rust 异步编程》

《[通过迭代 WebServer 逐步深入 Rust 异步编程](https://blog.windeye.top/rust_async/learningrustasyncwithwebserver)》

处理 TCP：从 单线程 👉 多线程 👉 非阻塞 👉 多路复用 👉 异步编程范式 的演进

| 演进                 | 演进前的缺点                                               | 演进后的优点                                         |
|----------------------|------------------------------------------------------------|------------------------------------------------------|
| 单线程 👉 多线程     | 执行每个 TCP 都是阻塞的，等待每个 TCP 处理完才能进行下一个 | 处理多个 TCP 是并发的                                |
| 多线程 👉 非阻塞     | 等待 TCP 的控制权在内核，用户态程序在等待过程中无法干预    | 请求不必等待，并且程序决定 TCP 被内核阻塞时，干什么  |
| 非阻塞 👉 多路复用   | 每个活跃连接在每个循环中发出一次系统调用，循环是低效的     | 内核跟踪所有活跃连接，一次循环只有一次系统调用       |
| 多路复用 👉 异步编程 | 用户程序手写事件循环来管理状态，代码混乱且难以拓展         | 用户程序编写独立的任务，并且事件处理和任务调度解耦合 |

在 Linux 上实现多路复用是通过 epoll 这个 I/O 事件通知机制做到的，核心系统调用 `epoll_wait` 会等待以下一个事件发生：
* 文件描述符传递了一个事件
* 调用被信号处理器中断
* 超时到期

如果这些事件都没发生，那么 epoll_wait 在用户态程序是阻塞的，不会往下执行；

如果其中一个事件发生，那么 epoll_wait 返回，程序往下执行，从而实现一次系统调用跟踪多个连接、减少循环中无用的系统调用。

