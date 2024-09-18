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

```bash
# 进入本地仓库目录
cd rust-rustlings-2024-*

# 确保 Rust 工具链安装成功并且可用

# 源码编译并安装 rustlings 可执行文件到 ~/.cargo/bin 目录
cargo install --force --path . 
```

#pagebreak()

#context {
  set text(size: 11pt)
  set block(spacing: 0pt, width: 103%)
  
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

== Q&A#todo

#set enum(numbering: "1.a)", tight: false, spacing: 10%)

#v(20pt)

+ 常见问题解答：https://github.com/LearningOS/rust-based-os-comp2024/blob/main/QA.md

+ 训练营第一阶段环境配置与学习资料：https://github.com/LearningOS/rust-based-os-comp2024/blob/main/2024-spring-scheduling-1.md

]