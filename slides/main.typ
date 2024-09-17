// doc: https://typst.app/universe/package/slydst/
#import "@preview/slydst:0.1.1": *

// local imports
#import "intro.typ": intro
#import "utils.typ": c, todo

// dark mode
// #set page(fill: rgb("808080")) // CACACA
// #set text(fill: rgb("000000"))

#set text(
  font: ("IBM Plex Serif", "Noto Sans CJK SC"), 
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
#show raw: it => block(
  fill: rgb("#04173E"),
  inset: 8pt,
  radius: 5pt,
  text(fill: rgb("#a2aabc"), it)
)

#intro

== Outline: Headings

#outline(
  target: heading.where(level: 1)
          .or(heading.where(level: 2))
)

== Outline: Figures

#outline(target: figure.where(kind: image))#todo#super()[
  #footnote()[#emph[TODO] 用于将春季链接更新到秋冬季链接，正式 PPT 应该删除]
]

= Rustlings

== Rustlings：Github 课堂

#let rustings_classroom = [
#link("https://classroom.github.com/assignment-invitations/f32787f1ff936b1bc45b8da4ffe4d738/status")[👉 进入课堂]
#todo
]

#figure(
  image("img/rustlings-classroom.png", height: 85%),
  caption: [#rustings_classroom]
)

== Rustlings：Github 课堂使用流程

#let rustings_rank(title) = [
#link("https://classroom.github.com/a/-WftLmvV")[#title]
#todo
]

+ Github 授权登陆课堂
+ 点击/复制 https://github.com/ 开头的仓库链接
+ 提交代码到该仓库
+ 每次推送到该仓库时，课堂系统会自动评分
+ 在 Actions 标签页可以查看评分过程
+ 查看评分结果
  - 在远程仓库选择 gh-pages 分支：Action 完成时自动推送到该分支
  - 或者查看#rustings_rank("排行榜")：定时向 Github 拉取，因此会有延迟

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