
#let content = [

  == Unsafe Rust

  #text(size: 10pt)[
    将 Rust 分为 Safe 和 Unsafe 两个子集：

    - *Safe Rust*：由编译器保证内存安全，当程序员违反规则，它报告错误并拒接编译代码；

    - *Unsafe Rust*：由程序员自己保证内存安全，编译器无法检查 unsafe 代码是否安全。
  ]

  #quote[
    // #set list(spacing: 12pt)
    #set block(spacing: 15pt)
    - Dereferencing a raw pointer.

    - Reading or writing a mutable or external static variable.

    - Accessing a field of a union, other than to assign to it.

    - Calling an unsafe function (including an intrinsic or foreign function).

    - Implementing an unsafe trait.

    #align(right)[
      src:
      #highlight(fill: orange, extent: 1.2pt)[
        #link("https://doc.rust-lang.org/reference/unsafety.html")[Reference: Unsafety]
      ]
    ]
  ]

  == `unsafe` 关键字

  #show table.cell: it => {
    if it.y == 0 {
      align(center + horizon, text(weight: "bold", fill: orange, it))
    } else {
      it
    }
  }
  #table(
    columns: (144pt, 152pt, auto),
    inset: 7pt,
    align: (horizon, horizon, center + horizon),
    table.header(
      [`unsafe` 代码],
      [功能],
      [谁保证安全条件],
    ),

    [
      - `unsafe fn`
      - `unsafe trait`
    ],
    [标识 *定义* 额外的安全条件],
    [该代码的*使用者*],

    [
      - `unsafe {}`
      - `unsafe impl`
      - `unsafe fn` without `unsafe_op_in_unsafe_fn`
    ],
    [标识 *满足* 额外的安全条件],
    [该代码的*编写者*],
  )

  #quote[
    #set block(spacing: 12pt)

    Unsafe functions (`unsafe fn`) are functions that are not safe in all contexts and/or for all possible inputs.

    We say they have extra safety conditions, which are requirements that must be upheld by all callers and that the compiler does not check.

    #align(right)[
      src:
      #highlight(fill: orange, extent: 1.2pt)[
        #link("https://doc.rust-lang.org/reference/unsafe-keyword.html")[Reference: The unsafe keyword]
      ]
    ]
  ]


]