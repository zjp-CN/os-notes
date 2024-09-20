#import "utils.typ": *

#let content = [

  #import "install/rust.typ"
  #rust.install

  #import "install/rustlings.typ"
  #rustlings.install

  #import "rustlings/chapters.typ"
  #chapters.content

  #import "rustlings/help.typ"
  #help.content

  #import "rustlings/watch.typ"
  #watch.content

  #import "rustlings/run.typ"
  #run.content

  #import "rustlings/list.typ"
  #list.content

  #import "rustlings/lsp.typ"
  #lsp.content

  #import "rustlings/qa.typ"
  #qa.content

]
