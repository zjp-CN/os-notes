# io_uring

整理自：<https://kernel.dk/io_uring.pdf>

## 背景

以前 Linux 的文件 IO 调用以传统的同步功能为主，异步功能设计不佳并且性能不好。

synchronous interfaces:

* read(2), write(2): oldest and most basic
* pread(2), pwrite(2): allow passing in of an offset
* preadv(2), pwritev(2): vector-based
* preadv2(2), pwritev2(2): allow modifier flags

asynchronous interface:

* aio_read(3), aio_write(3): POSIX, lackluster, poor performance
* native async IO interface (aio):
  * only supports async IO for O_DIRECT (or un-buffered) accesses; cache bypassing and size/alignment restraints
  * for normal (buffered) IO, the interface behaves in a synchronous manner
  * if meta data is required to perform IO, the submission will block waiting for that
  * API isn't great and is slow: 104 bytes of memory copy, for IO that's supposedly zero copy; always requires at least two system calls (submit + wait-for-completion)

Arrival of devices that are capable of both sub-10usec latencies and very high IOPS, but 
submission latencies are slow and non-deterministic.

aio 经历了错误的改进之路，认为在原来的接口上进行改进，工作量少、复用现有的测试设施，又能避免新接口的缺点（需要长时间地审查、完成和采用）。
但实际上，东补西补只会把代码越变越复杂，更难维护。

修改原来的接口导致工作量更大，最终放弃修复原来的接口，只能重新设计接口。

新接口设计目标，重要性从低到高，尽管有些目标是互斥的：
* 易用，但不容易误用
* 可拓展 (Extendable)：虽然背景问题主要是 block oriented IO，但是希望支持 networking 和 non-block storage，甚至为将来的新接口设计形状
* 功能丰富：成为应用的一部分（的一部分）；不要只满足部分应用的功能；避免应用重新实现相同的功能（比如 IO 线程池）
* 高效：仍然必须提高 block storage IO 效率；但在不携带数据的请求上，减少每个请求的开销
* 大规模可拓展 (Scalability)：在高峰时段提供最佳性能也很重要


## io_uring

最初的设计就是考虑效率，而且必须一开始就考虑效率，而不是在接口做好之后才考虑。

在提交和完成事件上，不要复制内存，也不要间接的内存。因此，内核和应用之间共享内存和 IO 结构，然后处理同步问题。

在处理同步问题上，如果应用和内核共享锁，那么需要系统调用，这会降低效率：因此使用单生产者单消费者环形缓冲区，避免共享锁和一些内存顺序、屏障上的技巧。

异步接口的两个基本操作：
* 提交请求：submission queue (SQ)
  * 提交 IO 请求时：应用是生产者，内核是消费者
* 该请求完成时的关联事件：completion queue (CQ)
  * 完成事件时：内核是生产者，应用是消费者

```c
struct io_uring_cqe { // Completion Queue Event
  __u64 user_data;
  __s32 res;
  __u32 flags;
};
```

* `user_data`：来自初始的请求提交，包含应用识别请求的信息；通常用于指向原请求；内核不触碰该字段；
* `res`：表示请求的结果，就像系统调用的返回值那样；对于常规的读取，它像 read(2) 或 write(2) 的返回值；
  * 成功时，表示传输的字节数；
  * 失败时，是一个负数错误码（比如出现 IO 错误，值为 `-EIO`）；
* `flags`：该操作相关的元数据，目前未被使用。


```c
struct io_uring_sqe { // Submission Queue Entry
  __u8 opcode;
  __u8 flags;
  __u16 ioprio;
  __s32 fd;
  __u64 off;
  __u64 addr;
  __u32 len;
  union {
    __kernel_rwf_t rw_flags;
    __u32 fsync_flags;
    __u16 poll_events;
    __u32 sync_range_flags;
    __u32 msg_flags;
  };
  __u64 user_data;
  union {
    __u16 buf_index;
    __u64 __pad2[3];
  };
};
```

sqe 不仅需要包含完成事件的信息，还需要包含将来拓展到其他请求类型的信息。 

* `opcode`：该请求的操作码，比如 `IORING_OP_READV` 表示 vectored read；
* `flags`：modifier flags that are common across command types；
* `ioprio`：该请求的优先级，对于常规读写，其含义见 `ioprio_set (2)`；
* `fd`：该请求关联的文件描述符；
* `off`：该操作应该发生的偏移量；
* `addr` 和 `len`：
  * 如果操作码表示 non-vetored 读写，那么 addr 表示该操作应该执行 IO 的地址，len 表示传输的字节数；
  * 如果是一个 vectored 读写，那么它指向 struct iovec array，用于 `preadv(2)`，len 表示传输的向量数；
* 第一个 union 与操作码相关，比如对于 `IORING_OP_READV`，flags 对应于 `preadv2 (2)`；
* `user_data`：在所有操作码上都不会被内核触碰，它只会复制给 cqe；
* `buf_index`：见高级用例
* 最后是一些 padding 字节：既用于 64 字节对齐，又用于将来添加请求描述数据时保留位置
  * 比如键值存储的命令
  * 或者端对端数据保护：传递应用写入数据的预先计算校验和


## communication channel

Completion Queue:

> Since the cqe's are produced by the kernel, only the kernel is actually modifying
> the cqe entries. The communication is managed by a ring buffer. Whenever a new event is posted by the kernel to the
> CQ ring, it updates the tail associated with it. When the application consumes an entry, it updates the head. Hence, if
> the tail is different than the head, the application knows that it has one or more events available for consumption. The
> ring counters themselves are free flowing 32-bit integers, and rely on natural wrapping when the number of completed
> events exceed the capacity of the ring. One advantage of this approach is that we can utilize the full size of the ring
> without having to manage a "ring is full" flag on the side, which would have complicated the management of the ring.
> With that, it also follows that the ring must be a power of 2 in size.

Submission Queue:

> The application is the one updating the tail, and the kernel consumes
> entries (and updates) the head. One important difference is that while the CQ ring is directly indexing the shared array
> of cqes, the submission side has an indirection array between them. Hence the submission side ring buffer is an index
> into this array, which in turn contains the index into the sqes. This might initially seem odd and confusing, but there's
> some reasoning behind it. Some applications may embed request units inside internal data structures, and this allows
> them the flexibility to do so while retaining the ability to submit multiple sqes in one operation. That in turns allows for
> easier conversion of said applications to the io_uring interface.
> 
> As soon as an sqe is consumed by the kernel, the application is free to reuse that sqe entry. This is true even for cases
> where the kernel isn't completely done with a given sqe yet. If the kernel does need to access it after the entry has been
> consumed, it will have made a stable copy of it. Why this can happen isn't necessarily important, but it has an
> important side effect for the application. Normally an application would ask for a ring of a given size, and the
> assumption may be that this size corresponds directly to how many requests the application can have pending in the
> kernel. However, since the sqe lifetime is only that of the actual submission of it, it's possible for the application to
> drive a higher pending request count than the SQ ring size would indicate. The application must take care not to do so,
> or it could risk overflowing the CQ ring. By default, the CQ ring is twice the size of the SQ ring. This allows the
> application some amount of flexibility in managing this aspect, but it doesn't completely remove the need to do so. If
> the application does violate this restriction, it will be tracked as an overflow condition in the CQ ring. 


Completion events may arrive in any order, there is no ordering between the request submission and the association
completion. The SQ and CQ ring run independently of each other. However, a completion event will always correspond
to a given submission request. Hence, a completion event will always be associated with a specific submission request.


## 其他资料

* 《[[译] Linux 异步 I/O 框架 io_uring：基本原理、程序示例与性能压测（2020）](https://arthurchiao.art/blog/intro-to-io-uring-zh)》


## 名词解释


<details>

<summary>
来自 Kimi (AI)，仅供参考。
</summary>


<div style="font-size: 3.5rem"><code>read(2)</code> 中的 2 的含义</div>

在 Unix 和类 Unix 操作系统中，`read(2)` 中的数字 `2` 表示这是一个系统调用的手册页（man page）的节编号。Unix 手册页被分为多个节，每个节用于描述不同类型的文档：

1. **第 1 节（Section 1）**：用户命令和程序。
2. **第 2 节（Section 2）**：系统调用和库函数。
3. **第 3 节（Section 3）**：库函数，与第 2 节不同，这些是 C 库提供的函数。
4. **第 4 节（Section 4）**：特殊文件、驱动程序和内核接口。
5. **第 5 节（Section 5）**：文件格式和约定。
6. **第 6 节（Section 6）**：游戏和娱乐程序。
7. **第 7 节（Section 7）**：杂项（包括宏和约定）。
8. **第 8 节（Section 8）**：系统管理和维护命令。

`read(2)` 指的是第 2 节中的 `read` 系统调用，它属于系统调用的范畴。当你在终端中输入 `man 2 read` 时，你会得到关于 `read` 系统调用的手册页，其中包含了该系统调用的详细描述、函数原型、参数、返回值、错误代码等信息。这种编号方式有助于用户快速定位到他们需要查看的手册页部分。

<div style="font-size: 3.5rem"><code>_t</code> 后缀</div>

在C语言中，类型后缀 `_t` 通常用来表示该类型是一个类型定义（typedef），它为一个基本数据类型提供一个更具描述性的名称。这种命名约定有助于提高代码的可读性和可维护性。以下是一些常见的带有 `_t` 后缀的类型：

1. **size_t**：表示对象大小的无符号整数类型。
2. **ssize_t**：表示有符号的大小或计数的整数类型。
3. **ptrdiff_t**：表示两个指针之间的差值的有符号整数类型。
4. **intptr_t** 和 **uintptr_t**：分别表示有符号和无符号的整数类型，用于存储指针值。
5. **uint8_t**、**int8_t**、**uint16_t**、**int16_t**、**uint32_t**、**int32_t**、**uint64_t**、**int64_t**：分别表示8位、16位、32位和64位的无符号和有符号整数类型。
6. **float_t** 和 **double_t**：表示浮点数的类型，通常用于实现内部的浮点数操作。

这些类型定义通常在 `<stddef.h>`、`<stdint.h>` 和 `<limits.h>` 等标准头文件中定义。使用 `_t` 后缀的目的是为了让类型名称更具描述性，从而使得代码更加清晰和易于理解。例如，`size_t` 比简单的 `unsigned int` 更能清楚地表达其用途和含义。


<div style="font-size: 3.5rem">read/write 及其变体的签名</div>

它们都定义在`unistd.h`头文件中：

1. **read(2)**：
   ```c
   ssize_t read(int fd, void *buf, size_t count);
   ```
   - `fd`：文件描述符。
   - `buf`：指向缓冲区的指针，用于存储读取的数据。
   - `count`：要读取的字节数。

2. **write(2)**：
   ```c
   ssize_t write(int fd, const void *buf, size_t count);
   ```
   - `fd`：文件描述符。
   - `buf`：指向包含要写入数据的缓冲区的指针。
   - `count`：要写入的字节数。

3. **pread(2)**：
   ```c
   ssize_t pread(int fd, void *buf, size_t count, off_t offset);
   ```
   - `fd`：文件描述符。
   - `buf`：指向缓冲区的指针，用于存储读取的数据。
   - `count`：要读取的字节数。
   - `offset`：相对于文件开始处的偏移量。

4. **pwrite(2)**：
   ```c
   ssize_t pwrite(int fd, const void *buf, size_t count, off_t offset);
   ```
   - `fd`：文件描述符。
   - `buf`：指向包含要写入数据的缓冲区的指针。
   - `count`：要写入的字节数。
   - `offset`：相对于文件开始处的偏移量。

5. **preadv(2)**：
   ```c
   ssize_t preadv(int fd, const struct iovec *iov, int iovcnt, off_t offset);
   ```
   - `fd`：文件描述符。
   - `iov`：指向`iovec`结构体数组的指针，每个`iovec`包含一个内存地址和要读取的长度。
   - `iovcnt`：`iovec`数组中的元素数量。
   - `offset`：相对于文件开始处的偏移量。

6. **pwritev(2)**：
   ```c
   ssize_t pwritev(int fd, const struct iovec *iov, int iovcnt, off_t offset);
   ```
   - `fd`：文件描述符。
   - `iov`：指向`iovec`结构体数组的指针，每个`iovec`包含一个内存地址和要写入的长度。
   - `iovcnt`：`iovec`数组中的元素数量。
   - `offset`：相对于文件开始处的偏移量。

这些系统调用的返回值通常是读取或写入的字节数，如果发生错误则返回-1，并设置`errno`以指示错误原因。`pread`和`pwrite`系列调用不会改变文件的当前偏移量，而`read`和`write`系列调用会改变文件的当前偏移量。`preadv`和`pwritev`允许从文件中分散读取或向文件分散写入数据。


<div style="font-size: 3.5rem"> offload</div>

**Offload** 是一个在计算机科学和网络技术中常用的术语，指的是将某些计算或处理任务从一个系统或组件转移到另一个系统或组件，以减轻主系统的负担，提高效率。

Offload 的定义:
在一般意义上，offload 指的是将不想要的负担或任务转移给其他人或系统。例如，在计算机网络中，可以将数据处理任务从CPU转移到网络接口卡（NIC）上，以降低CPU的负担并提高处理性能。

Offload 在存储系统中的应用:
在存储系统中，offload 技术常用于优化内存使用。例如，在深度学习模型训练过程中，当GPU显存不足时，可以将部分数据暂时存储到CPU内存中，从而释放GPU显存用于计算。此外，offload 还可以用于数据预处理和长期数据存储，以减少对昂贵存储资源的占用。

Offload 技术可以分为多种类型，主要包括：
- **TCP Offload Engine (TOE)**：将TCP连接过程中的计算任务转移到专用硬件（如网卡），以释放CPU资源。
- **Large Segment Offload (LSO)** 和 **Large Receive Offload (LRO)**：分别用于将数据包的分段和合并工作转移到网卡硬件上，从而提高网络性能。
- **Dynamic Computation Offloading**：在AI框架中，offload技术用于将模型权重和中间结果卸载到CPU或其他存储系统，以优化内存使用。

Offload 的优势:
- **性能提升**：通过将计算任务转移到更适合的硬件上，可以显著提高系统的整体性能。
- **资源优化**：减少主系统的负担，使其能够更专注于关键任务。
- **灵活性**：支持在不同设备和资源之间动态分配任务，提高系统的灵活性和响应能力。

总之，offload 是一种有效的技术手段，广泛应用于计算机系统、网络和存储管理中，以提高性能和优化资源使用。


</details>

