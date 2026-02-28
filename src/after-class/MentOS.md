
> [MentOS]: An educational open source 32-bit linux-like Operating System.
>
> The goal of MentOS is to provide a project environment that is realistic enough to show how a real Operating System work, yet simple enough that students can understand and modify it in significant ways.

[MentOS]: https://mentos-team.github.io/

# C 语言基础

[Slides: C Programming](https://mentos-team.github.io/doc/1_c_programming.pdf)

自己的总结：

|          | C             | Rust                                                    |
|----------|---------------|---------------------------------------------------------|
| 字节类型 | char          | u8                                                      |
| 字节切片 | `char buf[]`  | `buf: &[u8]` 或者 `buf: *const [u8]` 或者类似的可变版本 |
| 二级切片 | `char *buf[]` | `buf: &[CStr]` 等；C 的字符串编码需要额外处理           |
| 宏       | `#define`     | 声明宏、过程宏                                          |

# 基本概念

[Slides: Fundamental concepts](https://mentos-team.github.io/doc/2_fundamental_concepts.pdf)

* 进程的内存布局
* 文件描述符
* 系统调用、errno、strace
* `<sys/types.h>`
* `man <command>`

# 文件系统

[Slides: Filesystem](https://mentos-team.github.io/doc/3_filesystem.pdf)

主要是文件系统调用的使用说明和示例代码。

* 文件：open, read, write, lseek, close, unlink, stat, access, chmod
  * mode_t：文件类型和权限位
* 目录：mkdir, rmdir, opendir, closedir, readir

