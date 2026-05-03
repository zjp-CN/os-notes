
> [MentOS]: An educational open source 32-bit linux-like Operating System.
>
> The goal of MentOS is to provide a project environment that is realistic enough to show how a real Operating System work, yet simple enough that students can understand and modify it in significant ways.

[MentOS]: https://mentos-team.github.io/

# C 语言基础

[Slides: C Programming](https://mentos-team.github.io/doc/1_c_programming.pdf)

自己的总结：

|              | C                             | Rust                                                    |
|--------------|-------------------------------|---------------------------------------------------------|
| 字节类型     | char                          | u8                                                      |
| 字节切片[^1] | `char buf[]`                  | `buf: &[u8]` 或者 `buf: *const [u8]` 或者类似的可变版本 |
| 二级切片     | `char *buf[]` 或 `char **buf` | `buf: &[CStr]` 等；C 的字符串编码需要额外处理           |
| 宏           | `#define`                     | 声明宏、过程宏                                          |

[^1]: C 的数组长度通常在函数参数传递时丢失。

* `pid_t getpid(void);` 涉及 [K&R C vs ANSI C](https://www.kimi.com/share/19ca7892-7202-85a4-8000-000042929ed4)

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

# 进程

[Slides: Processs](https://mentos-team.github.io/doc/4_process.pdf)

## 信息

ID 信息：

| syscall | 含义                                                                          |
|---------|-------------------------------------------------------------------------------|
| getpid  | 当前进程 ID                                                                   |
| getppid | 父进程 ID （总是成功）                                                        |
| getuid  | 发起的进程实际用户 ID                                                         |
| geteuid | 发起的进程生效的用户 ID （setuid 会让 other 用户以文件的 owner 用户角色鉴权） |

环境变量：
* 通过全局变量 `char **environ` 
* 或者 main 函数的第三个参数

```c
#include <stdlib.h>
// Returns pointer to (value) string, or NULL if no such variable exists
char *getenv(const char *name);
// Returns 0 on success, or -1 on error
int setenv(const char *name, const char *value, int overwrite);
// Returns 0 on success, or -1 on error
int unsetenv(const char *name);
```

## exit

终止进程；状态码 0 表示成功，其他表示失败。
* `void _exit(int status)` 直接终止
* `void exit(int status)` 
  * 调用 exit handlers（通过 `int atexit(void (*func)(void))` 注册退出句柄）
  * 刷新 stdio stream 缓冲区
  * 最后调用 `_exit`

## fork

`pid_t fork(void)` 通过复制进程资源（fd、内存）来创建新的进程
* 在父进程中，函数的返回值为子进程号（成功）或者 -1（失败）
* 在子进程中，fork 的返回值为 0
* 父子进程由内核决定调度的顺序，并从 fork 函数返回开始执行


## wait

* `pid_t wait(int *status)`
    * 阻塞当前进程（父进程），等待一个子进程完成，并回收这个子进程（清理子进程资源），并返回该进程号
    * 没有需要等待的子进程，则返回 -1，并且 errno 为 ECHILD
    * 如果子进程先于 wait 终止，并父进程没有通过 wait 之类的方式回收，那么在父进程结束之后，子进程被 init
      （其 pid 为 1）进程收养，并最终 wait 来回收进程资源
* `pid_t waitpid(pid_t pid, int *status, int options)`
    * 等待对象：
      * pid > 0：进程号为 pid
      * pid < -1：进程组号（pid 绝对值）中的一个进程
      * pid = 0：同一进程组中的一个进程
      * pid = -1：任何一个子进程
    * 等待选项 (options)：
      * WNOHANG：以非阻塞方式等待
      * WUNTRACED：当子进程被信号暂停 (stopped) 或者结束 (terminated) 的时候，等待返回
      * WCONTINUED：当子进程被 SIGCONT 信号恢复的时候，等待返回
      * 0：阻塞地等待结束的子进程
    * status：
      * 当子进程通过 `_exit` 终止，调用 `WIFEXITED(status)` 将得到 true，并可调用 `WEXITSTATUS(status)` 查看状态码
      * 当子进程通过 `kill` 终止，调用 `WIFSIGNALED(status)` 将得到 true，并可调用 `WTERMSIG(status)` 查看导致终止的信号码
      * 当子进程通过 `kill + stop` 暂停， 调用 `WIFSTOPPED(status)` 将得到 true，并可调用 `WSTOPSIG(status)` 查看暂停码
      * 当子进程通过 `kill + continue` 恢复，调用 `WIFCONTINUED(status)`  将得到 true

## PGID 和 SID

进程集合：
* 进程组 (group、PGID、setpgid) 用于信号控制：用于前台/后台作业切换、信号广播和传递（如 Ctrl+C 发给整个组）
* 会话 (session、SID、setsid) 用于终端控制：终端所有与关联、守护进程脱离
  * 进程组是会话的子集，会话包含多个进程组
  * 只有会话首进程能拥有控制终端，会话中的其余进程只能共享或者继承这个终端
    * 终端是内核针对一组进程的共享机制，实现统一的 IO（限于标准输入输出，即 fd 0/1/2）和信号控制
    * 终端区分了进程是前台还是后台：只有前台进程才能使用标准输入输出，后台无法使用它们（会被内核暂停）。使用
      `tcsetpgrp(tty_fd, pgid)` 转移终端的所有权给进程组（设置前台）。
  * 守护进程需要脱离终端，因此它不能是会话首进程：fork → setsid（成为会话首进程）→ fork → exit（首进程退出）
    → 剩余进程成为无终端关联的守护进程
* PID、PGID 和 SID 在数值上可以完全一样，但语义由被调用的函数决定

## exec

exec 是一系列的系统调用，将当前进程镜像替换成另一个进程镜像

```c
// None of the following returns on success, all return -1 on error.
int execl (const char *path, const char *arg, ... ); // ... variadic functions
int execlp(const char *path, const char *arg, ... );
int execle(const char *path, const char *arg, ... , char *const envp[]);
int execv (const char *path, char *const argv[]);
int execvp(const char *path, char *const argv[]);
int execve(const char *path, char *const argv[], char *const envp[]);
```

| exec | filepath | filename in `$PATH` | variadic | argv | caller's environment | passed-in environment |
|------|:--------:|:-------------------:|:--------:|:----:|:--------------------:|:---------------------:|
| l    |    ✅    |                     |    ✅    |      |          ✅          |                       |
| lp   |          |          ✅         |    ✅    |      |          ✅          |                       |
| le   |    ✅    |                     |    ✅    |      |                      |           ✅          |
| v    |    ✅    |                     |          |  ✅  |          ✅          |                       |
| vp   |          |          ✅         |          |  ✅  |          ✅          |                       |
| ve   |    ✅    |                     |          |  ✅  |                      |           ✅          |

示例：

```c
// l: 将每个命令行参数作为函数参数（需要 NULL 结尾）
execl("/usr/bin/printenv", "printenv", "HOME", (char *)NULL);

// le: 环境变量数组的最后一个元素需要以 NULL 结尾
char *env[] = {"HOME=/home/pippo", (char *)NULL};
execle("/usr/bin/printenv", "printenv", "HOME", (char *)NULL, env);

// v: 将命令行参数作为数组（最后以 NULL 结尾），传递给函数
char *args[] = {"Hello", "C", "Programming", NULL};
execv("./hello", args);

// vp: printenv 将从 $PATH 中查找
char *arg[] = {"printenv", "HOME", (char *)NULL};
execvp("printenv", arg);
```

* list 和 array 都应该以 NULL 结尾
* 第一个命令行参数通常是程序的名字
* 所有 exec 在成功时不返回，失败时才返回 -1

# IPC

* [Slides: System V and Semaphores](https://mentos-team.github.io/doc/5_IPC_semaphores_shared_memory.pdf)
* [Slides: Shared Memory and Message Queue](https://mentos-team.github.io/doc/6_IPC_system_v_message_queue.pdf)
* [Slides: Signal, Pipe, and Fifo](https://mentos-team.github.io/doc/7_IPC_signal_pipe_fifo.pdf)

## System V

System V (aka SysV)
* the fifth edition of commercial versions of the Unix operating system
* originally developed by AT&T and released in 1983

SysV IPC:
* Mechanisms that coordinate activities (like managing access to a given system
  resource) among cooperating processes
  * Semaphores: synchronize actions among processes
  * Message queues: pass messages among processes
  * Shared memory
  * Signals
  * Pipes
  * FIFOs
* IPC 系统调用
  * 创建/打开：msgget、semget、shmget
  * 键：IPC_PRIVATE （内核创建）、ftok（基于文件、用户创建）
  * 数据结构：msqid_ds、semid_ds、shmid_ds（都含有 ipc_perm）
  * 更新状态：msgctl、semctl、shmctl
  * 信号量：
    * semop：执行连续的信号量操作（原子性）
  * 共享内存：
    * shmat：将共享内存段附加到进程的地址空间，使进程可以访问共享内存中的数据
    * shmdt：进程分离指定的共享内存段
    * 子进程继承父进程的共享内存
    * 自动分离：exec 和进程终结的时候，共享内存自动从进程分离
  * 消息队列：
    * msgsnd：发送一条消息到消息队列
    * msgrcv：从消息队列中读取一条消息，并移除它
      * 参数 msgtype 的含义：0 表示第一条消息；大于 0 表示与发送时 mtype 相等的第一条；小于 0 
        表示其绝对值小于或等于发送时的 mtype 、取最小的、第一条
* IPC 命令行工具
  * 列出：ipcs
  * 移除：ipcrm

## 实时调度器

[Slides: Real-time Scheduler](https://mentos-team.github.io/doc/8_real_time_scheduler_basics.pdf)

RTOS (real-time operating system)：受时间约束的 OS
* Soft RTOS：通常或大致满足最后期限
  * Event-driven：基于优先级切换任务
* Hard RTOS：确定性地满足最后期限
  * Time-sharing：基于时钟中断切换任务

Time consistency：任务从接受到完成所花费的时间应该一致
* 时间长度的变化被称为 jitter
* hard RTOS 不应该有 jitter，因为它会破坏确定性

Linux 系统调用
* sched_setscheduler 设置进程的调度策略和优先级
  * 调度策略：SCHED_OTHER（RR+Time-sharing）、SCHED_FIFO（Event-driven）、SCHED_RR（Event-driven）、SCHED_BATCH、SCHED_IDLE
  * 值越小，优先级越高：0 最高优先级
  * Time quantum：将 CPU 让给另一个同优先级的进程的最大连续时间
