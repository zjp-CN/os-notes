#import "utils.typ": c

// community activity
#let community_names = [
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
    URLO#footnote[Rust 官方社区论坛：#link("https://users.rust-lang.org")[users.rust-lang.org]]\
    #link("https://users.rust-lang.org/u/vague/summary")[vague]
  ],
)
]

// open source works on materials
#let table_open_source_materials = [
#align(center,
table(
  columns: 2,
  align: center,
  table.header([笔记], [翻译]),
  [#link("https://www.yuque.com/zhoujiping/programming/rust-materials")[入门阶段搜集的资料]],
  [#link("https://zjp-cn.github.io/tlborm")[The Little Book of Rust Macros]],
  
  [#link("https://zjp-cn.github.io/os-notes/")[操作系统训练营笔记]],
  [#link("https://rust-chinese-translation.github.io/api-guidelines/")[Rust API Guidelines]],
  
  [#link("https://zjp-cn.github.io/rust-note/")[学习笔记（非入门向）]],
  [#link("https://zjp-cn.github.io/translation")[零碎的文章翻译]],
))
]

// open source projects
#let table_open_source_projects = [
#align(center,
table(
  columns: 2,
  align: center,
  table.header([项目], [简介]),
  
  [#link("https://github.com/os-checker/os-checker")[os-checker]], 
  [
    对 Rust 代码库运行一系列检查工具，\
    并对检查结果进行报告和统计
  ],
  
  [#link("https://github.com/zjp-CN/nvim-cmp-lsp-rs")[nvim-cmp-lsp-rs]], 
  [
    在 nvim-cmp 插件中，对 Rust-Analyzer 的\
    候选补全项进行有用的排序和筛选
  ],
  
  [#link("https://github.com/zjp-CN/term-rustdoc")[term-rustdoc]],
  [
    通过树结构浏览 Rust 代码文档，\
    并增强泛型 APIs 的阅读体验
  ],

  [#link("https://github.com/zjp-CN/rustdx")[rustdx]],
  [受 pytdx 启发的 A 股数据获取工具],
  
  [#link("https://github.com/josecelano/cargo-pretty-test")[cargo-pretty-test]],
  [通过树结构来美化 #c[cargo test] 输出],

  [#link("https://github.com/zjp-CN/mdbook-theme")[mdbook-theme]],
  [添加右侧 TOC 和修改主题的 mdbook 插件],
))
]

#let intro = [

#set table(
  fill: (x, y) => if y == 0 { rgb("#ffc832") },
  inset: (left: 1.5em, right: 1.5em),
)
#show table.cell: it => {
  if it.y == 0 {
    text(fill: black, weight: "bold", emph(it))
  } else {
    align(center + horizon, it)
  }
}

#v(6pt)
Rust 社区账号：
#community_names

#v(12pt)
Rust 资料贡献：
#table_open_source_materials

#v(10pt)
#link("https://zjp-cn.github.io/translations/")[其他翻译书籍]：Rand Book、Salsa Book、Helix Book 等

#pagebreak()

#align(center)[
  #text(weight: "bold", size: 15pt)[Rust 开源项目]
]

#table_open_source_projects

#v(15pt)
crates.io dashboard: #link("https://crates.io/users/zjp-CN")[zjp-CN]

]