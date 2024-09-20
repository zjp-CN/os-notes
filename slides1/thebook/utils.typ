#import "../utils.typ": *

/// bottom title
#let btitle(content) = [
  #align(center)[
    #v(10pt)
    #text(weight: "bold", size: 16pt, content)
  ]
]
