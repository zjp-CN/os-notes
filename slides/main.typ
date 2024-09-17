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

// #let todo(body) = {
//   set text(white, size: 8pt)
//   rect(
//     fill: gray,
//     radius: 4pt,
//     [#body],
//   )
// }

// 代码块样式
#show raw: it => block(
  fill: rgb("#04173E"),
  inset: 8pt,
  radius: 5pt,
  text(fill: rgb("#a2aabc"), it)
)

#intro

== Outline

#outline()

= section

== Rustlings


+ #link("https://classroom.github.com/a/-WftLmvV")[第一阶段 Rustlings 完成情况排行榜] #todo#super()[
  #footnote()[#emph[TODO] 用于将春季链接更新到秋冬季链接，正式 PPT 应该删除]
]


```typst
#import "@preview/slydst:0.1.1": *

#show: slides.with(
  title: "Insert your title here", // Required
  subtitle: none,
  date: none,
  authors: (),
  layout: "medium",
  ratio: 4/3,
  title-color: none,
)

Insert your content here.
```

```rust
let a = 1;
```




= First section

== First slide

#figure(image("img/tmp.png", width: 60%), caption: "测试图片 😀")

#v(1fr)

#lorem(20)