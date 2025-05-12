# async-uring

> io-uring on top of any async runtime using AsyncRead and AsyncWrite

修改后的仓库：<https://github.com/os-checker/async-uring>

原作者的仓库：<https://github.com/r58Playz/async-uring>

## 修改记录

### bench.sh 注释掉 Turbo Boost 操作

注释掉 bensh.sh 脚本中的如下行：

```bash
echo 1 | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
```

它用于禁用 Intel CPU 的 Turbo Boost 功能。

但在我的机器上，该路径不存在，并且根据 [WSL#3497](https://github.com/microsoft/WSL/issues/3497#issuecomment-415480902)，
WSL 并不能加载原生 Linux 模块，像 cpupower、msr 之类的东西都不存在。因此禁用 Turbo Boost 需要在 Windows 端操作。

也就是说，如下警告中的解决方案是虚假的，没有这些包，因此无法安装这些东西

```bash
$ cpupower 
WARNING: cpupower not found for kernel 5.15.167.4-microsoft

  You may need to install the following packages for this specific kernel:
    linux-tools-5.15.167.4-microsoft-standard-WSL2
    linux-cloud-tools-5.15.167.4-microsoft-standard-WSL2

  You may also want to install one of the following packages to keep up to date:
    linux-tools-standard-WSL2
    linux-cloud-tools-standard-WSL2

$ sudo apt install linux-tools-5.15.167.4-microsoft-standard-WSL2
E: Unable to locate package linux-tools-5.15.167.4-microsoft-standard-WSL2
E: Couldn't find any package by glob 'linux-tools-5.15.167.4-microsoft-standard-WSL2'
```

我在我的服务器上也没有这个路径，但 cpupower 显示的是

```bash
$ cpupower frequency-info
analyzing CPU 1:
  no or unknown cpufreq driver is active on this CPU
  CPUs which run at the same hardware frequency: Not Available
  CPUs which need to have their frequency coordinated by software: Not Available
  maximum transition latency:  Cannot determine or is not supported.
Not Available
  available cpufreq governors: Not Available
  Unable to determine current policy
  current CPU frequency: Unable to call hardware
  current CPU frequency:  Unable to call to kernel
  boost state support:
    Supported: no
    Active: no
```

它不支持 boost。

### 修复 echo 示例

我遇到如下错误：

```bash
# 第一个仓库为监听的地址
$ bash bench.sh echo 127.0.0.1:2345
    Finished `release` profile [optimized + debuginfo] target(s) in 0.23s
     Running `target/release/examples/echo '127.0.0.1:2345'`
Error: Io(Os { code: 22, kind: InvalidInput, message: "Invalid argument" })
```

通过运行 `uname -a` 命令，我发现 Windows WSL2 的 ubuntu 24 的内核版本为 5.15，不支持 5.18 之后的
[`setup_submit_all`](https://docs.rs/io-uring/0.7.6/io_uring/struct.Builder.html#method.setup_submit_all) 调用。

解决方式：
* 修改 async-uring 在构造 IoUring 上的 API，以支持 5.15 内核
* 或者在新版本的内核上运行 async-uring：我的服务器的内核版本为 6.8，在那上面成功运行

