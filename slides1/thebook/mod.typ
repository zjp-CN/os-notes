#import "../utils.typ": *

#let content = [

  #show: codly-init.with()
  #set codly(zebra-fill: none)

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
    ]
  ]

  #import "./variables-and-mutability.typ"
  #variables-and-mutability.content

]
