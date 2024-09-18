#import "utils.typ": *

#let install_rustlings = [
== 安装 Rust

#enum[
  设置 Rustup 镜像地址， 修改 `~/.zshrc` 或者 `~/.bashrc` 配置文件

```bash
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
```
][
  下载 Rust 工具链#footnote[该脚本会从上一步设置的镜像地址下载 Rustup]

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
][
  打开新的终端，或者在当前终端加载 Cargo 的环境变量

```bash
source $HOME/.cargo/env
```
][
  确认安装成功

```bash
rustc -vV # 正常应输出内容
```
]

#pagebreak()

#enum(
enum.item(5)[
  在 `~/.cargo/config.toml` 中设置 `crates.io` 镜像地址
  #footnote[
    对于 1.68 及其版本之后的工具链（比如你目前下载的），已经默认使用 rsproxy-sparse 协议下载，它意味着按需拉取 registry 数据，所以更快。但 Rust 操作系统的代码库可能固定的版本号早于 1.68，那么只能使用 git 协议。因此按需设置 replace-with。
  ]
]
)
```toml
[source.crates-io]
# 若工具链要求早于 1.68，则使用 replace-with = 'rsproxy'
replace-with = 'rsproxy-sparse'

[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"

[net]
git-fetch-with-cli = true
```

#pagebreak()

#enum(
enum.item(6)[
  有时代码库必须从 Github 下载，那么需要配置上网代理：
]
)
  
```bash
# 设置 git 代理
$ git config --global http.proxy localhost:7897

# 设置网络代理，比如 curl 会读取这些环境变量
export http_proxy=http://0.0.0.0:7897 
export https_proxy=http://0.0.0.0:7897
```

#block_help[
#emph[其他参考资料：]

- Rustup 官方说明：https://rustup.rs
- 字节跳动镜像网址#footnote[
    对于国内网络访问，推荐使用此镜像；上面设置镜像的步骤就来自该网站。
  ]：https://rsproxy.cn
- Cargo 官方手册： #link("https://doc.rust-lang.org/cargo/reference/config.html")[config.toml]
- #link("https://rcore-os.cn/rCore-Tutorial-Book-v3/chapter0/5setup-devel-env.html#rust")[rCore 教程 Rust 实验环境配置]
]

== 安装 rustlings CLI

#align(center)[
#v(30pt)

#block_help[#emph[
  强烈建议首先阅读仓库中的 README 文档，\
  尤其是训练营相关的中文部分。
]]

#v(20pt)

```bash
# 进入本地仓库目录
cd rust-rustlings-2024-*

# 确保 Rust 工具链安装成功并且可用

# 源码编译并安装 rustlings 可执行文件到 ~/.cargo/bin 目录
cargo install --force --path . 
```
]

#pagebreak()
#block_code_in_one_page(11pt)[#context { set block(width: 103%)
```bash
$ rustlings --help
Usage: rustlings [--nocapture] [-v] [<command>] [<args>]

Rustlings is a collection of small exercises to get you used to writing and reading Rust code

Options:
  --nocapture       show outputs from the test exercises
  -v, --version     show the executable version
  --help            display usage information

Commands:
  verify            Verifies all exercises according to the recommended order
  watch             Reruns `verify` when files were edited
  run               Runs/Tests a single exercise
  reset             Resets a single exercise using "git stash -- <filename>"
  hint              Returns a hint for the given exercise
  list              Lists the exercises available in Rustlings
  lsp               Enable rust-analyzer for exercises
  cicvverify        cicvverify
```
}
]

== 使用 rustlings CLI： `watch` 和 `run`

#block_code_in_one_page(12pt)[
```rust
Progress: [--------------------------------------------------] 0/110
⚠️  Compiling of exercises/intro/intro2.rs failed! Please try again. Here's the output:

error: 1 positional argument in format string, but no arguments were given
  --> exercises/intro/intro2.rs:11:21
   |
11 |     println!("Hello {}!");
   |                     ^^

error: aborting due to 1 previous error

Welcome to watch mode! You can type 'help' to get an overview of the commands you can use here.
```
]
#align(center)[#c[rustlings watch]]

#pagebreak()

#align(center)[
#block_code_in_one_page(12pt)[
```rust
⚠️  Compilation of exercises/intro/intro2.rs failed!, Compiler error message:

error: 1 positional argument in format string, but no arguments were given
  --> exercises/intro/intro2.rs:11:21
   |
11 |     println!("Hello {}!");
   |                     ^^

error: aborting due to 1 previous error
```
]
#c[rustlings run intro2]
#block_code_in_one_page(12pt)[
```rust
⠙ Compiling exercises/intro/intro2.rs...
Hello!

✅ Successfully ran exercises/intro/intro2.rs
```
]

#pagebreak()
#block_code_in_one_page(9pt)[
```
Progress: [------------------------------------------------------------] 0/110
⠉ Compiling exercises/intro/intro2.rs...
✅ Successfully ran exercises/intro/intro2.rs!

🎉 🎉  The code is compiling! 🎉 🎉

Output:
====================
Hello!

====================

You can keep working on this exercise,
or jump into the next one by removing the `I AM NOT DONE` comment:

 6 |  // hint.
 7 |
 8 |  // I AM NOT DONE
 9 |
Welcome to watch mode! You can type 'help' to get an overview of the commands you can use here.
```
]
#block_help[
  代码编译通过之后，记得移除 `// I AM NOT DONE` 这行注释
]


#block_code_in_one_page(9pt)[
```rust
Progress: [------------------------------------------------------------] 0/110
Progress: [>-----------------------------------------------------------] 1/110 (0.0 %)
⚠️  Compiling of exercises/variables/variables1.rs failed! Please try again. Here's the output:
error[E0425]: cannot find value `x` in this scope
  --> exercises/variables/variables1.rs:11:5
   |
11 |     x = 5;
   |     ^
   |
help: you might have meant to introduce a new binding
   |
11 |     let x = 5;
   |     +++

error[E0425]: cannot find value `x` in this scope
  --> exercises/variables/variables1.rs:12:36
   |
12 |     println!("x has the value {}", x);
   |                                    ^ not found in this scope

error: aborting due to 2 previous errors

For more information about this error, try `rustc --explain E0425`.
```
]

#block_code_in_one_page(9pt)[
```
...
For more information about this error, try `rustc --explain E0425`.

Welcome to watch mode! You can type 'help' to get an overview of the commands you can use here.
help
Commands available to you in watch mode:
  hint   - prints the current exercise's hint
  clear  - clears the screen
  quit   - quits watch mode
  !<cmd> - executes a command, like `!rustc --explain E0381`
  help   - displays this help message

Watch mode automatically re-evaluates the current exercise
when you edit a file's contents.
```
]

在 `rustlings watch` 命令下，遇到问题可以键盘输入 `help`，按回车，就会获得上述交互信息。它提示你可以继续输入 `hint` 或者 `!<cmd>` 来获得提示。

#block_code_in_one_page(9pt)[
```
hint
The declaration on line 8 is missing a keyword that is needed in Rust to create a new variable binding.
```
]

#pagebreak()

#block_code_in_one_page(9pt)[
```rust
!rustc --explain E0425
An unresolved name was used.

Erroneous code examples:

something_that_doesnt_exist::foo;
// error: unresolved name `something_that_doesnt_exist::foo`

// or:
trait Foo {
    fn bar() {
        Self; // error: unresolved name `Self`
    }
}

// or:
let x = unknown_variable;  // error: unresolved name `unknown_variable`

Please verify that the name wasn't misspelled and ensure that the identifier being referred to is valid for the given situation. Example: ...
```
]

#c[rustc --explain E0425] 命令解释了编译器提供的错误码的含义。

你也可在线查看这个错误码 #link("https://doc.rust-lang.org/error_codes/E0425.html")[E0425]。

#pagebreak()
#block_code_in_one_page(9.5pt)[
```
$ rustlings watch
Progress: 🎉 All exercises completed! 🎉

+----------------------------------------------------+
|          You made it to the Fe-nish line!          |
+--------------------------  ------------------------+
                          \\/
     ▒▒          ▒▒▒▒▒▒▒▒      ▒▒▒▒▒▒▒▒          ▒▒
   ▒▒▒▒  ▒▒    ▒▒        ▒▒  ▒▒        ▒▒    ▒▒  ▒▒▒▒
   ▒▒▒▒  ▒▒  ▒▒            ▒▒            ▒▒  ▒▒  ▒▒▒▒
 ░░▒▒▒▒░░▒▒  ▒▒            ▒▒            ▒▒  ▒▒░░▒▒▒▒
   ▓▓▓▓▓▓▓▓  ▓▓      ▓▓██  ▓▓  ▓▓██      ▓▓  ▓▓▓▓▓▓▓▓
     ▒▒▒▒    ▒▒      ████  ▒▒  ████      ▒▒░░  ▒▒▒▒
       ▒▒  ▒▒▒▒▒▒        ▒▒▒▒▒▒        ▒▒▒▒▒▒  ▒▒
         ▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▓▒▒▓▓▒▒▒▒▒▒▒▒
           ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
             ▒▒▒▒▒▒▒▒▒▒██▒▒▒▒▒▒██▒▒▒▒▒▒▒▒▒▒
           ▒▒  ▒▒▒▒▒▒▒▒▒▒██████▒▒▒▒▒▒▒▒▒▒  ▒▒
         ▒▒    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▒▒
       ▒▒    ▒▒    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▒▒    ▒▒
       ▒▒  ▒▒    ▒▒                  ▒▒    ▒▒  ▒▒
           ▒▒  ▒▒                      ▒▒  ▒▒

We hope you enjoyed learning about the various aspects of Rust!
```
]
]

== 使用 rustlings CLI： `lsp`

到目前为止，我们还没有真正开始 Rust 编程，因为我们没有充分利用现代语言的 LSP，来获得#emph[代码补全、跳转定义、错误检测、代码导航、重构工具、代码格式化]等 IDE 级别的语言服务。

#block_help[
Rust-Analyzer 是 Rust 官方支持的 LSP 实现，支持在不同编辑器中提供一致的语言服务体验。安装和配置见 #link("https://rust-analyzer.github.io/manual.html")[RA 官方手册]。
]

=== 安装 Rust-Analyzer

- 在 VSCode 上，你只需要
  #link("https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer")[搜索和点击安装按钮]，就能直接工作。
  
- 对于 JetBrains 软件，比如 RustRover，则自行查看其官方文档说明。

- 在其他编辑器上，你需要仔细阅读上面的手册链接，比如通过
  `rustup component add rust-analyzer` 命令安装它，并安装相关的编辑器插件。

- 我是 NeoVim 的重度使用者，最近三年几乎每天都通过 NeoVim 编码。如果你想使用它的话，可以参考我的#link("https://github.com/zjp-CN/nvim-config")[配置文件]。

```rust
Diagnostics:
This file is not included in any crates, so rust-analyzer can't offer IDE services.

If you're intentionally working on unowned files, you can silence this warning by adding "unlinked-file" to rustnalyzer.diagnostics.disabled in your settings. [unlinked-file]
```

== Q&A#todo

#set enum(numbering: "1.a)", tight: false, spacing: 10%)

#v(20pt)

+ 常见问题解答：https://github.com/LearningOS/rust-based-os-comp2024/blob/main/QA.md

+ 训练营第一阶段环境配置与学习资料：https://github.com/LearningOS/rust-based-os-comp2024/blob/main/2024-spring-scheduling-1.md

]