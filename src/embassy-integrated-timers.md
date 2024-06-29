# embassy: integrated-timers 和任务机制

通过区分定时任务和普通任务，来理解 embassy-executor 的 `integrated-timers` feature 带来的功能以及运行时内部的任务机制，包括
* 任务类别
* 任务调度与执行
* 任务的状态及其改变
* 任务添加和删除
* 任务与 Future 实现

由于这部分内容最初是作为 [rCore-embassy-timer](./rCore-embassy-timer.md) 的初稿，但感觉写得有些复杂，和 rCore 
关系也不太紧密，所以单独拎出来了。

当时用的腾讯文档，我也懒得迁移过来，索性就在那里完成。

内容见 《[embassy-executor 的 integrated-timers 和任务机制](https://docs.qq.com/doc/DTG1WWGRReXZ4V3NG)》。

