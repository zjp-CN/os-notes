#import "utils.typ": *

#let install = [

  #import "install/rust.typ"
  #rust.install

  #import "install/rustlings.typ"
  #rustlings.install

  #import "rustlings/watch-run.typ"
  #watch-run.usage
  
  #import "rustlings/lsp.typ"
  #lsp.usage

  #import "rustlings/qa.typ" as qa
  #qa.content

]