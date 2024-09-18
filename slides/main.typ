// doc: https://typst.app/universe/package/slydst/
#import "@preview/slydst:0.1.1": *

// local imports
#import "intro.typ": intro
#import "utils.typ": c, todo, outline_heading, pageref
#set page(numbering: "1")
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

= Rustlings

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

#set enum(numbering: "1.a)", tight: false, spacing: 4%)

#v(20pt)

+ Github 授权登陆课堂

+ 点击 https://github.com/ 开头的仓库链接，并把仓库克隆到本地#footnote[
  see #pageref(<github-ssh>)
]

```bash
git clone git@github.com:LearningOS/rust-rustlings-2024-*.git
```

+ 提交代码到该仓库
+ 每次推送到该仓库时，课堂系统会自动评分
+ 在 Actions 标签页可以查看评分过程
+ 查看评分结果

  - 在远程仓库选择 gh-pages 分支：Action 完成时自动推送到该分支
  
  - 或者查看#rustings_rank("排行榜")：定时从 Github 拉取数据，因此会有延迟

== Rustlings：查看评分结果

#figure(
  image("img/rustlings-score.png", height: 75%),
  caption: [ 通过 gh-pages 分支查看评分结果 ]
)

== Rustlings：排行榜

#figure(
  image("img/rustlings-rank.png", height: 86%),
  caption: [#rustings_rank("第一阶段 Rustlings 完成情况排行榜")]
)
  
== Q&A

https://github.com/LearningOS/rust-based-os-comp2024/blob/main/QA.md

https://github.com/LearningOS/rust-based-os-comp2024/blob/main/2024-spring-scheduling-1.md


= 附录

== Github 设置 SSH

<github-ssh>

#align(center)[
```bash
# 生成新的 SSH 密钥对文件
ssh-keygen -t ed25519 -C "your_email@example.com"

# 将公钥内容复制到 Github 账号 Settings 的 SSH keys 中
cat ~/.ssh/id_ed25519.pub
```
]

#figure(
  image("img/github-ssh.png", height: 150pt, width: 330pt, fit: "stretch"),
  caption: [Github 设置 SSH ]
)