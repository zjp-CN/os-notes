#import "../utils.typ": *

#let content = [


  == Rust 的宗旨


  #v(45pt)
  #let slogan = [#quote[
      #let size = 14pt
      #let eve(a) = {
        text(fill: rgb("deea3a"), weight: "bold", size, a)
      }
      #let r(a) = {
        text(fill: rgb("7CFC00"), weight: "bold", size, a)
      }
      #let eff(a) = {
        text(fill: rgb("FFA07A"), weight: "bold", size, a)
      }

      Empowering #eve[everyone] to build #r[reliable] and #eff[efficient] software.

      #text(fill: white)[
        让 #eve[每个人] 都能构建 #r[可靠] 和 #eff[高效] 的软件。
      ]

      #align(right)[
        src:
        #highlight(fill: orange, extent: 1.2pt)[
          #link("https://www.rust-lang.org/")[rust-lang.org]
        ]
      ]
    ]]

  #slogan
  #pagebreak()
  #slogan
  #text(size: 10.3pt)[
    - *everyone*：
      - 无关国籍、信仰、年龄、性别、教育背景...
      - 具有全球、开放和包容的社区支持

    - *reliable*：
      - 通过所有权模型和丰富的类型系统，在编译期间消除诸多错误，*保证内存和线程安全*
      - 一流的包管理工具 Cargo、良好的文档以及友好的编译器错误报告

    - *efficient*：
      - 无运行时和垃圾收集器，*内存高效*
      - 可生成高度优化的代码，*运行高效*
  ]

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
      #footnote[Rust 的零成本抽象还有其他方式，比如引用、ZST。]
    ]
  ]

  #text(size: 20pt)[#emph[Traits]]

  #text(size: 11.2pt, style: "italic")[
    - are Rust's sole notion of interface.
    - can be statically dispatched.
    - can be dynamically dispatched.
    - solve a variety of additional problems beyond simple abstraction. (Marker traits)
  ]

  #v(8pt)
  #block_help[
    *source: Rust Blog *
    - (2015/04/10) #link("https://blog.rust-lang.org/2015/04/10/Fearless-Concurrency.html")[Fearless Concurrency with Rust]

    - (2015/05/11) #link("https://blog.rust-lang.org/2015/05/11/traits.html")[Abstraction without overhead: traits in Rust]
  ]

]