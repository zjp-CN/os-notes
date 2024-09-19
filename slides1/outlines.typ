#import "utils.typ": *

#let toc = [
  #show outline.entry.where(level: 1): it => {
    v(12pt, weak: true)
    strong(it)
  }

  #show outline.entry.where(level: 2): it => {
    h(10pt)
    it
  }

  #outline_heading[Outline: Headings]
  #outline(
    target: heading.where(level: 1).or(heading.where(level: 2)),
  )

  // #pagebreak()

  #outline_heading[Outline: Figures]
  #outline(target: figure.where(kind: image))
  #todo#super()[
    #footnote()[#emph[TODO] 用于标记将春季链接更新到秋冬季链接，正式 PPT 中应该删除它。]
  ]
]
