#import "../utils.typ": *

#let content = [

== Rust 受到多种语言的影响

#quote[
- #emph[SML, OCaml]: algebraic data types, pattern matching, type inference, semicolon statement separation
- #emph[C++]: references, RAII, smart pointers, move semantics, monomorphization, memory model
- #emph[ML Kit, Cyclone]: region based memory management
- #emph[Haskell (GHC)]: typeclasses, type families
- #emph[Newsqueak, Alef, Limbo]: channels, concurrency
- #emph[Erlang]: message passing, thread failure, #strike[linked thread failure], #strike[lightweight concurrency]
- #emph[Swift]: optional bindings
- #emph[Scheme]: hygienic macros
- #emph[C\#]: attributes
- #emph[Ruby]: closure syntax, #strike[block syntax]
- #emph[NIL, Hermes]: #strike[typestate]
- #emph[Unicode Annex \#31]: identifier and pattern syntax

#align(right)[
  src: 
    #highlight(fill: orange, extent: 1.2pt)[
    #link("https://doc.rust-lang.org/reference/influences.html")[Reference: influences]
  ]
]
]



]