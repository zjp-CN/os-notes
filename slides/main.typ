// doc: https://typst.app/universe/package/slydst/
#import "@preview/slydst:0.1.1": *

// local imports
#import "intro.typ": intro
#import "utils.typ": *

// dark mode
// #set page(fill: rgb("808080")) // CACACA
// #set text(fill: rgb("000000"))

// fonts
#let font_text = {"IBM Plex Serif"}
#let font_code = {"Cascadia Mono"}
#let font_cjk = {"Noto Sans CJK SC"}

#set text(
  font: (font_text, font_cjk), 
  lang: "zh", 
  region: "cn",
  size: 16.5pt,
)

#show link: it => [
  #text(fill: rgb("#3366CC"), style: "italic", weight: "bold", it)
  // #text(fill: rgb("#3366CC"), style: "italic", weight: "bold", underline(it))
]

#show emph: it => {
  text(weight: "bold", it.body)
}

#show footnote.entry: it => {
  // let loc = it.note.location()
  // let num = numbering(
  //   "[1]: ",
  //   ..counter(footnote).at(loc),
  // )
  // text(size: 8pt)[ #num#it.note.body ]
  text(size: 8pt, it)
}

#show: slides.with(
  title: "Rust 编程语言简介", // Required
  subtitle: "2024 秋冬季开源操作系统训练营",
  date: none,
  authors: ("by 周积萍"),
  layout: "large",
  ratio: 4/3,
  title-color: none,
)

#set text(size: 12pt)

// 代码块样式
#show raw.where(block: true): it => block(
  fill: rgb("#eff0ff"),
  inset: 8pt,
  radius: 5pt,
  text(font: (font_code, font_cjk), weight: "bold", it)
)

#show raw.where(block: false): it => context {
  set highlight(top-edge: "ascender")
  set highlight(bottom-edge: "descender")
  text(font: (font_code, font_cjk), weight: "bold", size: 11pt, it)
  
}

#intro


#show outline.entry.where(
  level: 1
): it => {
  v(12pt, weak: true)
  strong(it)
}

#show outline.entry.where(
  level: 2
): it => {
  h(10pt); it
}

#outline_heading[Outline: Headings]
#outline(
  target: heading.where(level: 1)
          .or(heading.where(level: 2)),
)

#pagebreak()

#outline_heading[Outline: Figures]
#outline(target: figure.where(kind: image))#todo#super()[
  #footnote()[#emph[TODO] 用于标记将春季链接更新到秋冬季链接，正式 PPT 中应该删除它。]
]

= 第一阶段的目标：Rustlings

== Rustlings：进入 Github 课堂

#let rustings_classroom = [
#link("https://classroom.github.com/assignment-invitations/f32787f1ff936b1bc45b8da4ffe4d738/status")[👉 进入课堂]
#todo
]

#figure(
  image("img/rustlings-classroom.png", height: 85%),
  caption: [#rustings_classroom]
)

== Rustlings：课堂使用流程

#let rustings_rank(title) = [
#link("https://classroom.github.com/a/-WftLmvV")[#title]
#todo
]

#v(2pt)

#set enum(numbering: "1.a)", tight: false, spacing: 4%)

#enum[
  Github 授权登陆课堂；
][
  点击 https://github.com/ 开头的仓库链接，并把仓库克隆到本地 #footnote[
    这里为了免密码推送代码，使用了 SSH 协议的地址，因此你需要在 Github 上设置 SSH 密钥，见 #pageref(<github-ssh>)。
  ]；
```bash
git clone git@github.com:LearningOS/rust-rustlings-2024-*.git
```
][
  提交代码到该仓库；
```bash
git add . && git commit -m "done: exercise x" && git push
```
][
  每次推送到该仓库时，课堂系统会自动评分；
][
  在 Actions 标签页可以查看评分过程；
][
  查看评分结果：
  - 在远程仓库选择 gh-pages 分支：Action 完成时自动推送到该分支
  
  - 或者查看#rustings_rank("排行榜")：定时从 Github 拉取数据，因此会有延迟
]

== Rustlings：查看评分结果

#figure(
  image("img/rustlings-score.png", height: 75%),
  caption: [ 通过 gh-pages 分支查看评分结果 ]
)

== Rustlings：排行榜

#align(center)[
#block_note[
  #emph[注意：只有完成全部练习，满足 110 总分的同学才算完成第一阶段。]
]]

#figure(
  image("img/rustlings-rank.png", height: 78%),
  caption: [ 👉 #rustings_rank("第一阶段 Rustlings 完成情况排行榜")]
)

= Rustlings 环境配置

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

# 设置网络代理，比如 curl 会这些读取环境变量
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

== Q&A#todo

#set enum(numbering: "1.a)", tight: false, spacing: 10%)

#v(20pt)

+ 常见问题解答：https://github.com/LearningOS/rust-based-os-comp2024/blob/main/QA.md

+ 训练营第一阶段环境配置与学习资料：https://github.com/LearningOS/rust-based-os-comp2024/blob/main/2024-spring-scheduling-1.md

= 附录

#import "appendix.typ": *

#github_ssh