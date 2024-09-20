// doc: https://typst.app/universe/package/slydst/
#import "@preview/slydst:0.1.1": *

// local imports
#import "intro.typ": intro
#import "utils.typ": *

// dark mode
// #set page(fill: rgb("808080")) // CACACA
// #set text(fill: rgb("000000"))

// fonts
#let font_text = "IBM Plex Serif"
#let font_code = "Cascadia Mono"
#let font_cjk = "Noto Sans CJK SC"

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
  above: 8pt,
  text(font: (font_code, font_cjk), weight: "bold", it),
)

#show raw.where(block: false): it => (
  context {
    set highlight(top-edge: "ascender")
    set highlight(bottom-edge: "descender")
    text(font: (font_code, font_cjk), weight: "bold", it)
  }
)

#set enum(numbering: "1.a)", tight: false)

// BEGIN:
#intro

// outlines
#import "outlines.typ": *
#toc

= 第一阶段目标：完成 Rustlings

#import "rustlings.typ": *
#rustlings

= Rustlings 环境配置

#import "rustlings-installation-usage.typ"
#rustlings-installation-usage.content

= Rust 语言简介

#import "rust.typ"
#rust.content

= The Book

#import "./thebook/mod.typ" as thebook
#thebook.content


= 附录

#import "appendix.typ"
#appendix.content


#heading(outlined: false)[谢谢观看]
