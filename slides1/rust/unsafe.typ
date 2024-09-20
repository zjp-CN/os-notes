#import "../utils.typ": *

#let content = [

  == Unsafe Rust

  #text(size: 10.3pt)[
    #v(14pt)
    #set block(spacing: 18pt)
    #set list(spacing: 15pt)

    将 Rust 分为 Safe 和 Unsafe 两个子集
    #footnote[
        具有未定义行为 (#context {
          link(locate(<rust-ub>), "UB")
        })
        的 Unsafe Rust 代码被用于 Safe Rust 时，就发生了 Unsound。
    ]：

    - *Safe Rust*：*由编译器保证内存安全*，当程序员违反规则，它报告错误并拒接编译代码；

    - *Unsafe Rust*：*由程序员自己保证内存安全*，编译器无法检查 unsafe 代码是否安全。
  ]

  #quote(src: (
    "https://doc.rust-lang.org/reference/unsafety.html",
    "Reference: Unsafety",
  ))[
    - Dereferencing a raw pointer.

    - Reading or writing a mutable or external static variable.

    - Accessing a field of a union, other than to assign to it.

    - Calling an unsafe function (including an intrinsic or foreign function).

    - Implementing an unsafe trait.

  ]


]
