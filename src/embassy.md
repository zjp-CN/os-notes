> 子模块 embassy 是修改过的 [embassy](https://github.com/embassy-rs/embassy) fork。

> 本文主要记录如何分析 embassy 仓库代码，而不是介绍具体的分析结果。
>
> 关于 embassy 分析结果，见我的 `embassy: ` 开头的训练营笔记文章。

# `rust-toolchain.toml`

`rust-toolchain.toml` 和 `rust-toolchain-nightly.toml` 是用来设置和固定 Rust 工具链版本号的。

有两个文件是因为 embassy 分别在 stable Rust 和 nightly Rust 上提供支持。

```toml
[toolchain]
channel = "1.79"
components = [ "rust-src", "rustfmt", "llvm-tools" ]
targets = [
    "thumbv7em-none-eabi",
    "thumbv7m-none-eabi",
    "thumbv6m-none-eabi",
    "thumbv7em-none-eabihf",
    "thumbv8m.main-none-eabihf",
    "riscv32imac-unknown-none-elf",
    "wasm32-unknown-unknown",
]
```

对本地分析源码，这基本没什么用，因为它主要用来进行 CI 测试。

我通常都会把这些工具链配置删除，当需要某个编译目标时（比如 `thumbv7em-none-eabi`），才通过
`rustup target add thumbv7em-none-eabi` 添加。

对于新手，如果你觉得手动设置这些很麻烦，可以不用动它，但代价是它会给你下载这整套工具链，需要安装时间和存储空间。

# `.vscode/settings.json`

对于 vscode 用户，首先查看 embassy 根目录的 `.vscode/settings.json` 配置文件，里面主要是用来配置 rust-analyzer (RA)。

根据我的经验，embassy 仓库的项目结构已经属于中大型规模，如果你对 Rust 的 [cargo](https://doc.rust-lang.org/cargo/)
组织方式不够熟悉，那么很难进行随心所欲地变动和配置。

我不会在这深入分析 embassy 的项目结构。但项目结构会决定你怎么配置 RA，比如说默认开启的 

* `"rust-analyzer.cargo.target": "thumbv7em-none-eabi"`：它要求你的工具链安装了 `thumbv7em-none-eabi` 目标，它会在每个被分析到的库上，给
  cargo 传递 `--target thumbv7em-none-eabi` 来让 RA 获取 rustc 发出的诊断。这对于代码分析不是必要的，至少在我分析某些库的时候 （executor、
  time），我不需要指定它。但它可能会影响内联汇编，因为汇编语法与编译目标相关（我没有尝试分析那部分，这只是猜测）。
* `"rust-analyzer.linkedProjects": [...]`：这实质上是手动指定一些项目让 RA 分析；它有多种使用方式，最常用的一种是指向子目录中的
  `Cargo.toml`，这是因为 `Cargo.toml` 代表所在的目录是一个 package。

  > **rust-analyzer.linkedProjects (default: [])**
  > 
  > Disable project auto-discovery in favor of explicitly specified set of projects.
  > 
  > Elements must be paths pointing to Cargo.toml, rust-project.json, .rs files (which will be treated as standalone files) or JSON objects in rust-project.json format.
  >
  > src: [RA user manual](https://rust-analyzer.github.io/manual.html)

* `"rust-analyzer.cargo.features": [...]`：这与你分析的项目有关，由于 embassy 默认设置 `embassy-stm32/Cargo.toml` 作为分析，embassy 帮你填了
  `embassy-stm32/Cargo.toml` 内的一些 features；如果你修改 `linkedProjects` 到别的库，那么填那个库的 features。

  ```json
    "rust-analyzer.cargo.features": [
      // Comment out these features when working on the examples. Most example crates do not have any cargo features.
      "stm32f446re",
      "time-driver-any",
      "unstable-pac",
      "exti",
      "rt",
    ],
  ```

# neovim / 条件编译和宏展开示例

> vscode 用户可以不必阅读这一节，你们只需要上面的步骤，然后右键选择一下就能看到宏展开。
>
> 但这里的介绍流程和细节并不会因为编辑器/开发环境的不同而完全割裂。

我并不是 vscode 用户，而是长期通过终端使用 neovim 编码。

但我也不会在这从头讲如何基于 neovim 搭建开发环境；如果你想知道我的配置，见 [此处](https://github.com/zjp-CN/nvim-config)。

neovim 中 Rust LSP 插件主要是 [rustaceanvim](https://github.com/mrcjkb/rustaceanvim)，一些要点：
* 项目布局：
  * 方式一：你可以使用上面 vscode 那样的 linkedProjects 配置，那么想办法让插件读取 RA 的配置文件就好
  * 方式二：由于 embassy 根目录不是 workspace 布局，所以我通常从终端进入某个库开始对它分析，把 `rust-analyzer.json` 放置在那个库的根目录
* RA 配置：
  * `"rust-analyzer.cargo.allFeatures": false`：因为 embassy 是重度条件编译和 feature 控制的，它的库不需要 allFeatures
    * 其实 allFeatures 已经被弃用，这里只是防止插件给你设置（我得到 [教训](https://github.com/rust-lang/rust-analyzer/issues/17371)）
  * `"rust-analyzer.cargo.features": [...]`：（可选的）填写这个库所需的 features
  * `"rust-analyzer.cargo.cfgs"`：（可选的）填写这个库所需的 cfg
* embassy 同时也是重度使用宏的，尤其一些结合 build.rs + `include!` 进行编译时生成和展开源码的地方，更需要上面影响条件编译的选项配置正确
  * 在想要展开的宏上，调用 `:RustLsp expandMacro` 命令展开宏
  * 如果你想要通过 `cargo expand`，那么需要通过 `-F` 传递 features

综合示例：在 `embassy-stm32/src/lib.rs` 中，有一个 `include!(concat!(env!("OUT_DIR"), "/_generated.rs"))`，如果你没有传递 `stm32` 开头的 
feature，那么 RA 无法展开和分析其内部的代码。所以你需要类似于下面的配置

```json
{
  "rust-analyzer.cargo.allFeatures": false,
  "rust-analyzer.cargo.features": ["time-driver-tim1", "stm32c011d6"],
  "rust-analyzer.cargo.cfgs": ["time_driver_tim1"]
}
```

才直接展开这个 `include!` 宏，得到 `_generated` 模块的实际内容[^_generated]：

[^_generated]: 如果通过 `cargo expand`，示例为 `cargo expand _generated -F stm32c011d6 | bat -l rust` 展开 `_generated` 模块

![](./img/neovim-embassy-cfg-include.gif)

并获得只对 `time_driver_tim1` 条件编译的分析结果：

```rust
// embassy-stm32/src/time_driver.rs
// 其中 peripherals 模块由 _generated.rs 编译时生成，它在源码中不存在
   40   #[cfg(time_driver_tim1)]
   41   type T = peripherals::TIM1;
  42   #[cfg(time_driver_tim2)]     ● code is inactive due to #[cfg] directives: time_driver_tim2 is disabled
   43   type T = peripherals::TIM2;
  44   #[cfg(time_driver_tim3)]     ● code is inactive due to #[cfg] directives: time_driver_tim3 is disabled
   45   type T = peripherals::TIM3;
```


