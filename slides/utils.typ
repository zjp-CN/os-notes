// 带框的标签（用于短代码）
#let c(body) = {
  highlight(fill: orange, radius: 3pt, extent: 2pt, text(white, weight: "bold")[#body])
}

#let todo = {
    super(text(weight: "bold")[TODO])
}