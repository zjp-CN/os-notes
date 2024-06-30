
进展记录：[向老师的石墨文档](https://shimo.im/docs/KlkKvegZoeudw7qd)

# 每周任务（均完成）

* 第 2 周：[用户态协程（爬虫）](https://play.rust-lang.org/?version=stable&mode=debug&edition=2021&gist=404a64695ff36c37b18e4e3d92f849d1)
* 第 3 周：向 embassy 提交修复 Waker unsoundness 的 PR（已合并）
  * [embassy#3059: use nightly waker_getters APIs](https://github.com/embassy-rs/embassy/pull/3059)
  * [embassy#3069: minimize cfg code in task_from_waker](https://github.com/embassy-rs/embassy/pull/3069)
* 第 4-6 周：将 embassy 应用于 rCore 定时器驱动
  * 仓库地址：[rCore-tutorial-code-2024S-embassy](https://gitee.com/ZIP97/rCore-tutorial-code-2024S-embassy)
  * 文档：仓库 README 或者 [os-notes/rCore-embassy-timer](https://zjp-cn.github.io/os-notes/rCore-embassy-timer.html)

# 开发日志

* [rCore-N (共享调度器 fork) 搭建和踩坑](https://zjp-cn.github.io/os-notes/async-os-dev-log_rCore-N.html)
* [cortex-m-quickstart 的 qemu 模拟记录](https://zjp-cn.github.io/os-notes/cortex-m-quickstart.html)
* [embassy-usage](https://zjp-cn.github.io/os-notes/embassy-usage.html)（学习 embassy 时，自己编写的[示例仓库](https://gitee.com/ZIP97/embassy-usage)）
* [研究 embassy 库的经验之谈](https://zjp-cn.github.io/os-notes/embassy.html) （RA 配置、条件编译、check-cfg）
* [green-thread](https://zjp-cn.github.io/os-notes/green-thread.html)（整合绿色线程代码到单独的[仓库](https://gitee.com/ZIP97/green-thread)）

# 学习笔记

* [embassy: TaskStorage](https://zjp-cn.github.io/os-notes/embassy-task.html)
* [embassy: embassy_time_driver::Driver](https://zjp-cn.github.io/os-notes/embassy-timer.html)
* [embassy: sync](https://zjp-cn.github.io/os-notes/embassy-sync.html)：zerocopy_channel (SPSC) 和 MPMC Channel
* [embassy: integrated-timers 和任务机制](https://zjp-cn.github.io/os-notes/embassy-integrated-timers.html)：任务类别、任务调度与执行、任务的状态与改变、添加和删除任务、任务与 Future

# 其他工作

* 学习 rCore-N 共享调度器项目代码
* 学习 embassy std 例子时，使用 Miri 碰到 UB 和 ICE
  * 报告 ICE 给 Miri：[ICE due to overflow when using a large timeout with futexes](https://github.com/rust-lang/miri/issues/3647)
  * 在造成 UB 的 critical-section 仓库下留言，提供更多信息：[Mitigate Miri violation](https://github.com/rust-embedded/critical-section/pull/46)
* 每周线上讨论时准备的 PPT
  * [第 1 周](https://docs.qq.com/slide/DTE5Ta2FXZ1NjSldN)
  * [第 2 周](https://docs.qq.com/slide/DTFNkQ0hwaHp2TkxW)
  * [第 3 周](https://docs.qq.com/slide/DTHpYQ05HdGZwWUZv)
* 补充基础知识：反复观看讨论的视频回放，把里面提及的新知识全部查一遍
  * 【笔记】[专业名词集锦](https://zjp-cn.github.io/os-notes/terminology.html)
  * 【笔记】[专业名词集锦 2](https://zjp-cn.github.io/os-notes/terminology2.html)
  * 【笔记】[专业名词集锦 3](https://zjp-cn.github.io/os-notes/terminology3.html)
