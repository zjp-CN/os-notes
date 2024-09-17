// doc: https://typst.app/universe/package/slydst/
#import "@preview/slydst:0.1.1": *

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


#grid(
  columns: (1fr, 1fr, 1fr),
  align(center)[
    Github\
    #link("https://github.com/zjp-CN")[zjp-CN]
  ],
  align(center)[
    中文社区\
    #emph[苦瓜小仔]
  ],
  align(center)[
    URLO#footnote[Rust 官方社区论坛 #link("https://users.rust-lang.org")[users.rust-lang.org]]\
    #link("https://users.rust-lang.org/u/vague/summary")[vague]
  ],
)

#v(1fr)

#set table(
  fill: (x, y) => if y == 0 { gray },
  inset: (left: 1.5em, right: 1.5em),
)
#show table.cell: it => {
  if it.x == 0 or it.y == 0 {
    emph(it)
  } else {
    it
  }
}

#align(center,
table(
  columns: 2,
  align: center,
  table.header([笔记], [翻译]),
  [#link("https://www.yuque.com/zhoujiping/programming/rust-materials")[入门阶段搜集的资料]], [#link("https://zjp-cn.github.io/tlborm")[The Little Book of Rust Macros]],
  [#link("https://zjp-cn.github.io/os-notes/")[操作系统训练营笔记]], [#link("https://rust-chinese-translation.github.io/api-guidelines/")[Rust API Guidelines]],
  [#link("https://zjp-cn.github.io/rust-note/")[学习笔记（非入门向）]], [#link("https://zjp-cn.github.io/translation")[零碎的文章翻译]],
))

#v(1fr)

#align(center, )[
  aaa
]

#v(1fr)

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