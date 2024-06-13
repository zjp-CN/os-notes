# cortex-m-quickstart 的 qemu 模拟记录

时间：2024-06-13

[rust-embedded] 组织有一本关于 Rust 做嵌入式的书籍 《[The Embedded Rust Book]》。

[rust-embedded]: https://github.com/rust-embedded
[The Embedded Rust Book]: https://docs.rust-embedded.org/book/start/qemu.html

在那里有基于 qemu 模拟的 [cortex-m-quickstart] 项目流程介绍：<https://docs.rust-embedded.org/book/start/qemu.html>。

[cortex-m-quickstart]: https://github.com/rust-embedded/cortex-m-quickstart

整体过程非常清楚，我跑通了几个示例。那里有的细节我不在这里重复，但提取一下重点，补充一点细节吧。

## 环境准备

### rustup

使用 Rust 交叉编译需要相应的工具链。设置 Rust 工具链的方式主要有两种
* 项目内的固定工具链 `rust-toolchain.toml`（参考 [embassy/rust-toolchain.toml]，建议去掉那些你不想要的目标名）
* 通过 rustup 命令行灵活添加工具链，比如对于 `thumbv6m-none-eabi`，使用

[embassy/rust-toolchain.toml]: https://github.com/embassy-rs/embassy/blob/main/rust-toolchain.toml


```console
rustup target add thumbv7m-none-eabi
```


### qemu

虽然最新的版本是 9（鼓励使用最新版本），但我本地已经有 8.2.2，所以拿这个 8 的版本来说吧。

```console
cd /root/qemu/qemu-8.2.2 # 替换你本地解压后的 qemu 源码目录

# --target-list=arm-softmmu 指定了 ARM 架构的软模拟
# enable-pie 启用位置无关可执行文件
./configure --target-list=arm-softmmu --enable-pie

# 编译 qemu，二进制产物为 /root/qemu/qemu-8.2.2/build/qemu-system-arm
make -j$(nproc)
```

### gdb

和我之前编译 riscv 的流程是一样的，把目标平台从 `riscv64-unknown-elf` 改成 `arm-none-eabi`（编译目录也要换）。

嗯... 这些目标名是怎么知道的呢，我翻过 gdb 的手册，印象中有提到它的[目标三元组的编码规则][gdb-target] 为 `architecture-vendor-os`，但绝对没有直接给这些三元组列表 ：)

[gdb-target]: https://sourceware.org/gdb/current/onlinedocs/gdb.html/Config-Names.html#Config-Names

实际上，在 gdb 的文档里介绍两种方式去了解目标名：
1. 阅读随源码附带的 config.sub 脚本（这被用于 ./configure 脚本来替换缩写）
2. 运行这个脚本尝试三元组

相当原始和易于出错，因为根据文档：
* 当你尝试查询 `i386-linux`，会得到良好的 `i386-pc-linux-gnu`
* 而实际上如果你查询 `arm-eabi` ，会得到 `arm-unknown-eabi`，而不是 `arm-none-eabi`
* 查询 `arm-none` 呢？结果是 `arm-unknown-none`

是的，你只有输入 `arm-none-eabi` 才会得到良好的 `arm-none-eabi`。

你可能会争辩，使用 `arm-unknown-eabi` 就好了，可是经过搜索，从经验角度看，这似乎并不是一个常见的目标名。

unknown 和 none 肯定在含义上有交叉，但我真的没有兴趣去了解它们的区别。

背景故事结束，那么我在这把修改后的安装流程贴在这（gdb 的版本号自己改一下）：

```console
# 1. 首先一些依赖项，其中 libncurses5-dev 提供了 TUI 库（--enable-tui 需要它)
sudo apt-get install libncurses5-dev texinfo libreadline-dev # python python-dev 
# 这里的 python 和 python-dev 并不必须是 python2，我本地的默认 python 就是 3，可以编译成功并且正常使用

# 2. 检查本地 python 路径
which python # 或者 ll $(which python) 查看链接到那个 python，我的是 /usr/local/sbin/python -> /usr/bin/python3

# 3. 下载最新的 GDB 源码，清华镜像地址： https://mirrors.tuna.tsinghua.edu.cn/gnu/gdb/?C=M&O=D
wget https://mirrors.tuna.tsinghua.edu.cn/gnu/gdb/gdb-14.2.tar.xz

# 4. 解压缩它（你可以使用 tar 命令，我懒得查和记，因为我一直使用 ouch ），源码在 $PWD/gdb-14.2/ 文件夹下 
ouch d gdb-14.2.tar.xz

# 5. 进入这个目录，并在里面创建另一个目录，用来存放编译结果和二进制文件
cd gdb-14.2
mkdir build-arm-eabi

# 适当阅读一下 gdb-14.2/gdb/README，这可是 GDB 的官方安装说明

# 6. 进入 gdb-14.4/build-arm-eabi 目录，准备编译
cd build-arm-eabi
../configure --prefix=/root/qemu/gdb-14.2/build-arm-eabi --with-python=/usr/local/sbin/python --target=arm-none-eabi --enable-tui=yes

# 7. 编译并生成二进制文件 
make -j$(nproc)
make install

# 8. 编译好的 GDB 存放在 build-arm-eabi/bin/ 目录下，你可以只保留这个目录，然后添加这个目录到环境变量。
# 确认 GDB 可以运行
./bin/arm-none-eabi-gdb --version
# 在 `~/.bashrc` 文件中，添加以下一行，然后开启新的终端（或者重启终端），那么 
export PATH="/root/qemu/gdb-14.2/build-arm-eabi/bin:$PATH"

# 9. 安装 gdb-dashboard：仅仅是下载一个 python 文件到 ~/.gdbinit 来做 gdb 的启动拓展
wget -P ~ https://github.com/cyrus-and/gdb-dashboard/raw/master/.gdbinit
```

## cortex-m-quickstart 是什么

[cortex-m-quickstart] 是 ARM Cortex-M 微控制器项目的应用程序模板，相当于编写各个目标编译平台的最简应用程序。

具体有以下平台：

```toml
# .cargo/config.toml
[build]
# Pick ONE of these compilation targets
# target = "thumbv6m-none-eabi"    # Cortex-M0 and Cortex-M0+
# target = "thumbv7m-none-eabi"    # Cortex-M3
# target = "thumbv7em-none-eabi"   # Cortex-M4 and Cortex-M7 (no FPU)
# target = "thumbv7em-none-eabihf" # Cortex-M4F and Cortex-M7F (with FPU)
# target = "thumbv8m.base-none-eabi"   # Cortex-M23
# target = "thumbv8m.main-none-eabi"   # Cortex-M33 (no FPU)
# target = "thumbv8m.main-none-eabihf" # Cortex-M33 (with FPU)
```

我在官方 qemu 上成功运行和（结合 gdb）调试过 thumbv7m-none-eabi 和 thumbv7em-none-eabihf。

## thumbv7m-none-eabi

book 里面的例子就是基于 `examples/hello.rs` 文件，一种做法是修改 `.cargo/config.toml` 文件
* 把 `[build]` 键的 `target = "thumbv7m-none-eabi"` 取消注释，这样 `cargo build` 无需指定目标名就能交叉编译那个目标
* 然后在 `[target.thumbv7m-none-eabi]` 键，编写 qemu 的运行命令，这样 `cargo run` 就能通过 qemu 运行那个目标的二进制文件

```toml
[target.thumbv7m-none-eabi]
# uncomment this to make `cargo run` execute programs on QEMU
runner = "qemu-system-arm -cpu cortex-m3 -machine lm3s6965evb -nographic -semihosting-config enable=on,target=native -kernel"

[build]
target = "thumbv7m-none-eabi"
```

book 介绍了使用 gdb 进行调试，需要两个终端来分别运行这两个步骤：

```console
# 步骤1： qemu 运行二进制，通过 3333 端口让 gdb 远程调试
qemu-system-arm \
  -cpu cortex-m3 \
  -machine lm3s6965evb \
  -nographic \
  -semihosting-config enable=on,target=native \
  -gdb tcp::3333 \
  -S \
  -kernel target/thumbv7m-none-eabi/debug/examples/hello

# 步骤2：gdb 调试
arm-none-eabi-gdb -ex 'file target/thumbv7m-none-eabi/debug/examples/hello' -ex 'target remote :3333'
```

有一些坑：
* qemu 官方只支持 stm32 的部分机器，[见其文档](https://www.qemu.org/docs/master/system/arm/stm32.html)，或者通过
  `qemu-system-arm -machine help` 进行查询（见 [附录 1]）
* gdb 也不一定支持一些目标架构，通过 `arm-none-eabi-gdb -ex 'set arch' -q` 可以看到没有 armv7m 
  架构（但有 armv7 和 armv7e-m）。可能这造成 gdb 运行 `start` 命令却无法执行程序（但远程调试可以执行和调试）。

```console
>>> set architecture
arm, armv2, armv2a, armv3, armv3m, armv4, armv4t, armv5, armv5t, armv5te,
xscale, ep9312, iwmmxt, iwmmxt2, armv5tej, armv6, armv6kz, armv6t2, armv6k,
armv7, armv6-m, armv6s-m, armv7e-m,
armv8-a, armv8-r, armv8-m.base, armv8-m.main, armv8.1-m.main, armv9-a, arm_any, auto

>>> start
Don't know how to run.  Try "help target".
```

[附录 1]: #附录-1qemu-支持的-arm-机器列表

整体来说，这套做法适用于单目标编译，但不适用于多目标编译。

我将在下一小节给出 makefile 来根据 example 名设置编译目标和 gdb 相关的命令。

## thumbv7em-none-eabihf

这个编译目标没有在 book 作为示例。

我测试它主要是因为 gdb 支持 armv7e-m 架构，用来测试 gdb 能不能直接执行程序，结果是不能，还是得远程调试才行。

这里直接贴 makefile 内容，这是不同于上一小节的启动方式，所以不需要动 `.cargo/config.toml` 文件。

```makefile
qemu := /root/qemu/qemu-8.2.2/build/qemu-system-arm

bin ?= hello

ifeq ($(bin),device)
	cpu := cortex-m4
	machine := netduinoplus2  
	target := thumbv7em-none-eabihf
	device_cargo := echo "\033[41m\033[1mCargo.toml needs stm32f3 dependency for device example: uncomment it\033[0m"
else
	cpu := cortex-m3
	machine := lm3s6965evb  
	target := thumbv7m-none-eabi 
	device_cargo :=
endif

build:
	@$(device_cargo)
	cargo build --example $(bin) --target $(target)

run: build
	$(qemu) \
  -cpu $(cpu) \
  -machine $(machine) \
  -nographic \
  -semihosting-config enable=on,target=native \
  -kernel target/$(target)/debug/examples/$(bin)

gdbserver: build
	$(qemu) \
  -cpu $(cpu) \
  -machine $(machine) \
  -nographic \
  -semihosting-config enable=on,target=native \
  -gdb tcp::3333 \
  -S \
  -kernel target/$(target)/debug/examples/$(bin)


GDB_PATH := /root/qemu/gdb-14.2/build-arm-eabi/bin/arm-none-eabi-gdb
gdb := RUST_GDB=$(GDB_PATH) rust-gdb

gdbclient:
	$(gdb) -ex 'file target/$(target)/debug/examples/$(bin)' -ex 'target remote :3333'
```

使用说明：
* 先把第一行 qemu 的路径改成你本地的 
* `make build`、`make run`、`make gdbserver` 和 `make gdbclient` 默认都是运行示例 hello 
* `thumbv7em-none-eabihf` 对应的示例为 device，在上述 make 子命令中添加 `bin=device` 即可运行或者调试
  * 注意：需要取消注释 Cargo.toml 中的 `[dependencies.stm32f3]` 整个表，因为 device 需要 stm32f3 依赖
  * `make run bin=device` 运行程序
  * 两个终端分别运行 `make gdbserver bin=device` 和 `make gdbclient bin=device`

## 附录 1：官方 qemu 支持的 arm 机器列表

```console
# qemu arm 模拟器支持的机器（每行末尾括号内为 cpu 型号，传递给 -cpu 参数，但注意改成小写）
$ /root/qemu/qemu-8.2.2/build/qemu-system-arm -machine help
Supported machines are:
akita                Sharp SL-C1000 (Akita) PDA (PXA270)
ast1030-evb          Aspeed AST1030 MiniBMC (Cortex-M4)
ast2500-evb          Aspeed AST2500 EVB (ARM1176)
ast2600-evb          Aspeed AST2600 EVB (Cortex-A7)
bletchley-bmc        Facebook Bletchley BMC (Cortex-A7)
borzoi               Sharp SL-C3100 (Borzoi) PDA (PXA270)
bpim2u               Bananapi M2U (Cortex-A7)
canon-a1100          Canon PowerShot A1100 IS (ARM946)
cheetah              Palm Tungsten|E aka. Cheetah PDA (OMAP310)
collie               Sharp SL-5500 (Collie) PDA (SA-1110)
connex               Gumstix Connex (PXA255)
cubieboard           cubietech cubieboard (Cortex-A8)
emcraft-sf2          SmartFusion2 SOM kit from Emcraft (M2S010)
fby35-bmc            Facebook fby35 BMC (Cortex-A7)
fby35                Meta Platforms fby35
fp5280g2-bmc         Inspur FP5280G2 BMC (ARM1176)
fuji-bmc             Facebook Fuji BMC (Cortex-A7)
g220a-bmc            Bytedance G220A BMC (ARM1176)
highbank             Calxeda Highbank (ECX-1000)
imx25-pdk            ARM i.MX25 PDK board (ARM926)
integratorcp         ARM Integrator/CP (ARM926EJ-S)
kudo-bmc             Kudo BMC (Cortex-A9)
kzm                  ARM KZM Emulation Baseboard (ARM1136)
lm3s6965evb          Stellaris LM3S6965EVB (Cortex-M3)
lm3s811evb           Stellaris LM3S811EVB (Cortex-M3)
mainstone            Mainstone II (PXA27x)
mcimx6ul-evk         Freescale i.MX6UL Evaluation Kit (Cortex-A7)
mcimx7d-sabre        Freescale i.MX7 DUAL SABRE (Cortex-A7)
microbit             BBC micro:bit (Cortex-M0)
midway               Calxeda Midway (ECX-2000)
mori-bmc             Mori BMC (Cortex-A9)
mps2-an385           ARM MPS2 with AN385 FPGA image for Cortex-M3
mps2-an386           ARM MPS2 with AN386 FPGA image for Cortex-M4
mps2-an500           ARM MPS2 with AN500 FPGA image for Cortex-M7
mps2-an505           ARM MPS2 with AN505 FPGA image for Cortex-M33
mps2-an511           ARM MPS2 with AN511 DesignStart FPGA image for Cortex-M3
mps2-an521           ARM MPS2 with AN521 FPGA image for dual Cortex-M33
mps3-an524           ARM MPS3 with AN524 FPGA image for dual Cortex-M33
mps3-an547           ARM MPS3 with AN547 FPGA image for Cortex-M55
musca-a              ARM Musca-A board (dual Cortex-M33)
musca-b1             ARM Musca-B1 board (dual Cortex-M33)
musicpal             Marvell 88w8618 / MusicPal (ARM926EJ-S)
n800                 Nokia N800 tablet aka. RX-34 (OMAP2420)
n810                 Nokia N810 tablet aka. RX-44 (OMAP2420)
netduino2            Netduino 2 Machine (Cortex-M3)
netduinoplus2        Netduino Plus 2 Machine (Cortex-M4)
none                 empty machine
npcm750-evb          Nuvoton NPCM750 Evaluation Board (Cortex-A9)
nuri                 Samsung NURI board (Exynos4210)
olimex-stm32-h405    Olimex STM32-H405 (Cortex-M4)
orangepi-pc          Orange Pi PC (Cortex-A7)
palmetto-bmc         OpenPOWER Palmetto BMC (ARM926EJ-S)
qcom-dc-scm-v1-bmc   Qualcomm DC-SCM V1 BMC (Cortex A7)
qcom-firework-bmc    Qualcomm DC-SCM V1/Firework BMC (Cortex A7)
quanta-gbs-bmc       Quanta GBS (Cortex-A9)
quanta-gsj           Quanta GSJ (Cortex-A9)
quanta-q71l-bmc      Quanta-Q71l BMC (ARM926EJ-S)
rainier-bmc          IBM Rainier BMC (Cortex-A7)
raspi0               Raspberry Pi Zero (revision 1.2)
raspi1ap             Raspberry Pi A+ (revision 1.1)
raspi2b              Raspberry Pi 2B (revision 1.1)
realview-eb          ARM RealView Emulation Baseboard (ARM926EJ-S)
realview-eb-mpcore   ARM RealView Emulation Baseboard (ARM11MPCore)
realview-pb-a8       ARM RealView Platform Baseboard for Cortex-A8
realview-pbx-a9      ARM RealView Platform Baseboard Explore for Cortex-A9
romulus-bmc          OpenPOWER Romulus BMC (ARM1176)
sabrelite            Freescale i.MX6 Quad SABRE Lite Board (Cortex-A9)
smdkc210             Samsung SMDKC210 board (Exynos4210)
sonorapass-bmc       OCP SonoraPass BMC (ARM1176)
spitz                Sharp SL-C3000 (Spitz) PDA (PXA270)
stm32vldiscovery     ST STM32VLDISCOVERY (Cortex-M3)
supermicro-x11spi-bmc Supermicro X11 SPI BMC (ARM1176)
supermicrox11-bmc    Supermicro X11 BMC (ARM926EJ-S)
sx1                  Siemens SX1 (OMAP310) V2
sx1-v1               Siemens SX1 (OMAP310) V1
tacoma-bmc           OpenPOWER Tacoma BMC (Cortex-A7)
terrier              Sharp SL-C3200 (Terrier) PDA (PXA270)
tiogapass-bmc        Facebook Tiogapass BMC (ARM1176)
tosa                 Sharp SL-6000 (Tosa) PDA (PXA255)
verdex               Gumstix Verdex Pro XL6P COMs (PXA270)
versatileab          ARM Versatile/AB (ARM926EJ-S)
versatilepb          ARM Versatile/PB (ARM926EJ-S)
vexpress-a15         ARM Versatile Express for Cortex-A15
vexpress-a9          ARM Versatile Express for Cortex-A9
virt-2.10            QEMU 2.10 ARM Virtual Machine
virt-2.11            QEMU 2.11 ARM Virtual Machine
virt-2.12            QEMU 2.12 ARM Virtual Machine
virt-2.6             QEMU 2.6 ARM Virtual Machine
virt-2.7             QEMU 2.7 ARM Virtual Machine
virt-2.8             QEMU 2.8 ARM Virtual Machine
virt-2.9             QEMU 2.9 ARM Virtual Machine
virt-3.0             QEMU 3.0 ARM Virtual Machine
virt-3.1             QEMU 3.1 ARM Virtual Machine
virt-4.0             QEMU 4.0 ARM Virtual Machine
virt-4.1             QEMU 4.1 ARM Virtual Machine
virt-4.2             QEMU 4.2 ARM Virtual Machine
virt-5.0             QEMU 5.0 ARM Virtual Machine
virt-5.1             QEMU 5.1 ARM Virtual Machine
virt-5.2             QEMU 5.2 ARM Virtual Machine
virt-6.0             QEMU 6.0 ARM Virtual Machine
virt-6.1             QEMU 6.1 ARM Virtual Machine
virt-6.2             QEMU 6.2 ARM Virtual Machine
virt-7.0             QEMU 7.0 ARM Virtual Machine
virt-7.1             QEMU 7.1 ARM Virtual Machine
virt-7.2             QEMU 7.2 ARM Virtual Machine
virt-8.0             QEMU 8.0 ARM Virtual Machine
virt-8.1             QEMU 8.1 ARM Virtual Machine
virt                 QEMU 8.2 ARM Virtual Machine (alias of virt-8.2)
virt-8.2             QEMU 8.2 ARM Virtual Machine
witherspoon-bmc      OpenPOWER Witherspoon BMC (ARM1176)
xilinx-zynq-a9       Xilinx Zynq Platform Baseboard for Cortex-A9
yosemitev2-bmc       Facebook YosemiteV2 BMC (ARM1176)
z2                   Zipit Z2 (PXA27x)
```
