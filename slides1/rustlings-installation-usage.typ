#import "utils.typ": *

#let content = [

  #import "install/rust.typ"
  #rust.install

  #import "install/rustlings.typ"
  #rustlings.install

  #import "rustlings/watch.typ" as watch
  #watch.usage

  #import "rustlings/run.typ"
  #run.usage

  #import "rustlings/list.typ"
  #list.usage
  
  #import "rustlings/lsp.typ"
  #lsp.usage

  #import "rustlings/qa.typ" as qa
  #qa.content

]