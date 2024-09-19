#import "utils.typ": *

#let content = [

#set quote(block: true)
#show quote: it => {
  set block(fill: rgb("3c3966"), inset: 8pt, width: 105%)
  set text(fill: white, size: 10.5pt)
  it
}
#show emph: it => { text(fill: orange, it) }
  
  #import "rust/slogan.typ"
  #slogan.content

  #import "rust/influences.typ"
  #influences.content

  #import "rust/unsafe.typ"
  #unsafe.content
  
]
