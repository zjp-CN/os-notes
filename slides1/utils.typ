#import "@preview/codly:1.0.0": *

#let codeblock_bg = rgb("#eff0ff")

// 带框的标签（用于短代码）
#let c(code) = {
  highlight(
    fill: orange,
    radius: 3pt,
    extent: 2pt,
    text(white, weight: "bold")[#code],
  )
}

#let todo = {
  super(text(weight: "bold")[TODO])
}


// 更改大纲目录的标题样式
#let outline_heading(body) = {
  align(center)[
    #text(
      stroke: 0.2pt + rgb("00008B"),
      fill: rgb("024782"),
      weight: "bold",
      size: 20pt,
      [
        #show heading: none
        #heading[#body]
        #body
      ],
    )
  ]
}

// src: https://github.com/typst/typst/issues/2873#issuecomment-1842438663
#let pageref(label) = (
  context {
    let loc = locate(label)
    // let content = query(label.first().value )
    link(loc)[第 #loc.page() 页]
  }
)

#let block_help(content) = {
  block(
    fill: rgb("f0f9ed"),
    stroke: 1.5pt + rgb("63d34a"),
    inset: 8pt,
    radius: 12pt,
    content,
  )
}

#let block_note(content) = {
  align(center)[
    #block(fill: rgb("f94343"), inset: 8pt)[
      #text(fill: white, content)
    ]
  ]
}

// 缩小字体到一页的代码块
#let block_code_in_one_page(size, body) = [
  #text(size, body)
]

#let quote(src: none, width: 100%, size: 10.5pt, content) = {
  block(fill: rgb("3c3966"), inset: 9pt, width: width)[
    #set text(fill: white, size)
    #content
    #if src != none {
      let (uri, text) = src
      align(right)[
        src:
        #highlight(fill: orange, extent: 1.2pt)[ #link(uri, text) ]
      ]
    }
  ]
}
