
## 注意：应基于缓冲区所有权来编写健全的面向完成的 API

`tokio_uring` 的 [buffer](https://docs.rs/tokio-uring/0.5.0/tokio_uring/buf/index.html) 抽象排除了 `&'a [u8]`
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
