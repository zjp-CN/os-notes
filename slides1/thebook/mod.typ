#import "utils.typ": *

#let content = [

  #show: codly-init.with()
  // #set page(footer: none)

  == 阅读地址

  #align(center + horizon)[
    #set text(size: 18pt)
    #block_help[
      *Rust 官方入门书籍*

      《
      #link(
        "https://doc.rust-lang.org/book",
        "The Rust Programming Language",
      )
      》

      中文版

      《
      #link(
        "https://kaisery.github.io/trpl-zh-cn",
        "Rust 程序设计语言",
      )
      》

      语法速查手册

      #link(
        "https://cheats.rs/",
        "cheats.rs",
      )
    ]
  ]

  #show emph: it => text(fill: orange, it)

  #import "./variables-and-mutability.typ"
  #variables-and-mutability.content

  #import "./scalar-primitive-compound-types.typ"
  #scalar-primitive-compound-types.content

  #import "./functions.typ"
  #functions.content

  #import "./comments.typ"
  #comments.content

  #import "./control-flow.typ"
  #control-flow.content

]
