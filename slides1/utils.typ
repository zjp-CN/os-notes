// 带框的标签（用于短代码）
#let c(code) = {
  highlight(fill: orange, radius: 3pt, extent: 2pt, text(white, weight: "bold")[#code])
}

#let todo = {
    super(text(weight: "bold")[TODO])
}


// 更改大纲目录的标题样式
#let outline_heading(body) = {
align(center)[
#text(
  stroke: 0.2pt + rgb("00008B"), fill: rgb("024782"),
  weight: "bold", size: 20pt,
  [
    #show heading: none
    #heading[#body]
    #body
  ]
)
]
}

// src: https://github.com/typst/typst/issues/2873#issuecomment-1842438663
#let pageref(label) = context {
  let loc = locate(label)
  // let content = query(label.first().value )
  link(loc)[第 #loc.page() 页]
}

#let block_help(content) = {
  block(
    fill: rgb("f0f9ed"), 
    stroke: 1.5pt + rgb("63d34a"),
    inset: 8pt, radius: 12pt,
    content
  )
}

#let block_note(content) = {
  block(fill: rgb("f94343"), inset: 8pt)[
    #text(fill: white, content)
  ]
}

// 缩小字体到一页的代码块
#let block_code_in_one_page(size, body) = [
#context {
  set text(size: size)
  set block(spacing: 0pt)
  body
}
]
