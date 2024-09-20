#import "../utils.typ": *

#let content = [

  == Rust 的三大基石

  #align(center)[
    #quote[How do you do safe systems programming?]
    Memory safety without garbage collection.

    #quote[How do you make concurrency painless?]
    Concurrency without data races#footnote[
      #set text(style: "italic")
      A data race is any unsynchronized, concurrent access to data involving a write.
    ].
  ]

  #text(size: 20pt)[#emph[Ownership]]

  #text(size: 11.2pt, style: "italic")[
    In Rust, every value has an "owning scope," and passing or returning a value means transferring ownership ("moving" it) to a new scope. Values that are still owned when a scope ends are automatically destroyed at that point.
  ]

  #text(size: 20pt)[#emph[Borrowing]]

  #text(size: 11.2pt, style: "italic")[
    #show raw.where(block: false): it => (
      context {
        text(fill: orange, it)
      }
    )

    If you have access to a value in Rust, you can lend out that access to the functions you call. Rust will check that these leases do not outlive the object being borrowed.

    Each reference is valid for a limited scope, which the compiler will automatically determine. References come in two flavors:

    - Immutable references `&T`, which allow sharing but not mutation. *There can be multiple `&T` references to the same value simultaneously, but the value cannot be mutated while those references are active.*

    - Mutable references `&mut T`, which allow mutation but not sharing. *If there is an `&mut T` reference to a value, there can be no other active references at that time, but the value can be mutated.*

    Rust checks these rules at compile time; borrowing has no runtime overhead.
  ]

  #pagebreak()

  #align(center)[
    #quote[Abstraction without overhead
      #footnote[Rust 的零成本抽象还有其他例子，比如引用、迭代器、ZST 等。]
    ]
  ]

  #text(size: 20pt)[#emph[Traits]]

  #text(size: 11.2pt, style: "italic")[
    - are Rust's sole notion of interface
    - can be statically dispatched
    - can be dynamically dispatched
    - solve a variety of additional problems beyond simple abstraction (Marker traits)
  ]

  #v(8pt)
  #block_help[
    *source: Rust Blog *
    - (2015/04/10) #link("https://blog.rust-lang.org/2015/04/10/Fearless-Concurrency.html")[Fearless Concurrency with Rust]

    - (2015/05/11) #link("https://blog.rust-lang.org/2015/05/11/traits.html")[Abstraction without overhead: traits in Rust]
  ]

]

