#import "utils.typ": *

#let content = [

  #show emph: it => text(fill: orange, it)

  #import "rust/slogan.typ"
  #slogan.content

  #import "rust/cornerstone.typ"
  #cornerstone.content

  #import "rust/influences.typ"
  #influences.content

  #import "rust/unsafe.typ"
  #unsafe.content

  #import "rust/growing.typ"
  #growing.content

  #import "rust/appendix.typ"
  #appendix.content

]
