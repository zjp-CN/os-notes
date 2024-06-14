# Qemu 有两种运行模式

时间：2024-04-29

## `qemu-system-riscv64`

`qemu-system-riscv64` 模拟系统级模拟一台 RISC-V 64 裸机，它包含处理器、内存及其他外部设备，支持运行完整的操作系统。

常用以下命令启动内核：

```shell
qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios ../bootloader/rustsbi-qemu.bin \
    -device loader,file=target/riscv64gc-unknown-none-elf/release/os,addr=0x80200000
```

* 默认提供 128 MiB 物理内存 （`[0x80000000,0x88000000)`）
* `rustsbi-qemu.bin` 会被放在以物理地址 0x80000000 开头的物理内存中
* `rustsbi-qemu.bin` 约定内核的入口地址为 0x80200000
* `file` 参数需要内核的二进制文件
  * qemu 支持带元数据的 ELF 文件，无需去除它们
  * 老版本的 qemu 不支持的话，或者想要精简大小，可使用
    `rust-objcopy --strip-all target/riscv64gc-unknown-none-elf/release/os -O binary target/riscv64gc-unknown-none-elf/release/os.bin`

与 rust-gdb 搭配：

```shell
# server
qemu-system-riscv64 \
    -machine virt \
    -nographic \
    -bios ../bootloader/rustsbi-qemu.bin \
    -device loader,file=target/riscv64gc-unknown-none-elf/release/os,addr=0x80200000 \
    -s -S

# gdb client
RUST_GDB=path/to/riscv64-unknown-elf-gdb rust-gdb \
    -ex 'file target/riscv64gc-unknown-none-elf/release/os' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'
```

对于 `qemu-system-riscv64`，只需在上述命令添加 `-s -S` 来开放 1234 端口给 gdb。
由于对 Rust 程序进行调试，使用 rust-gdb 这个 Rust 自带的 gdb 包装器来获得更好的调试体验。
[有无 rust-gdb 的区别见这里][rust-gdb]。

[rust-gdb]: https://zjp-CN.github.io/posts/rcore-gdb/#使用-rust-gdb

对 rust-gdb 来说，`RUST_GDB` 与 `gdb` 等价，但环境变量的优先级更高。如果你的环境中 gdb
命令指向 `riscv64-unknown-elf-gdb`，那么可以无需 `RUST_GDB`。如果采用环境变量，最好把它添加到
`~/.bashrc` 中，以免每次运行 `rust-gdb` 都要写。


## `qemu-riscv64`

`qemu-riscv64` 模拟了用户模式，直接支持运行 RISC-V 64 用户程序 （`qemu-riscv64 path/to/a-elf-file`）。

它实际上是一个 RISC-V 架构下的 Linux 操作系统，需要做到二者的系统调用的接口是一样的（包括系统调用编号，参数约定的具体的寄存器和栈等）。

它相当于已经提供了 OS 层，或者说模拟一台预装了 Linux 操作系统的 RISC-V 计算机，但仅支持载入并执行单个可执行文件。具体来说，它可以解析基于
RISC-V 的应用级 ELF 可执行文件，加载到内存并跳转到入口点开始执行。在翻译并执行指令时，如果碰到是系统调用相关的汇编指令，它会把不同处理器（如
RISC-V）的 Linux 系统调用转换为本机处理器（如 x86-64）上的 Linux 系统调用，这样就可以让本机 Linux 完成系统调用，并返回结果（再转换成 RISC-V
能识别的数据）给这些应用。

与 rust-gdb 搭配：

```shell
# server
qemu-riscv64 -g 1234 path/to/a-elf-file

# gdb client
rust-gdb \
    -ex 'file path/to/a-elf-file' \
    -ex 'set arch riscv:rv64' \
    -ex 'target remote localhost:1234'
```

* 环境变量 `QEMU_GDB` 与 `-g` 参数等价： 即 `QEMU_GDB=1234 qemu-riscv64 path/to/a-elf-file` 和 `qemu-riscv64 -g 1234 path/to/a-elf-file` 等价
* `-g` 必须放置于 elf 路径之前，否则会当作 elf 的参数，因为 `qemu-riscv64 [options] program [arguments...]`

