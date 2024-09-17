// doc: https://typst.app/universe/package/slydst/
#import "@preview/slydst:0.1.1": *

#import "intro.typ": intro

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
  // #set text(fill: rgb("#3366CC"), style: "italic", weight: "bold")
  // #underline(it.body)
  #text(fill: rgb("#3366CC"), style: "italic", weight: "bold", underline(it))
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

#intro

== Outline

#outline()

= section

Insert your content here.

中文 

？？？



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