// 带框的标签（用于短代码）
#let c(code) = {
  highlight(fill: orange, radius: 3pt, extent: 2pt, text(white, weight: "bold")[#code])
}

#let todo = {
    super(text(weight: "bold")[TODO])
}

#let outline_heading(body) = {
align(center)[
#text(
  stroke: 0.2pt + rgb("00008B"), fill: rgb("024782"),
  weight: "bold", size: 20pt,
  [#body]
)
]
}

// src: https://github.com/typst/typst/issues/2873#issuecomment-1842438663
#let pageref(label) = context {
  let loc = locate(label)
  // let content = query(label.first().value )
  link(loc)[第 #loc.page() 页]
}