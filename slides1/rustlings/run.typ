#import "../utils.typ": *

#let content = [

  == #c[rustlings run]

  #align(center)[
    #block_code_in_one_page(12pt)[
      ```rust
      ⚠️  Compilation of exercises/intro/intro2.rs failed!, Compiler error message:

      error: 1 positional argument in format string, but no arguments were given
        --> exercises/intro/intro2.rs:11:21
         |
      11 |     println!("Hello {}!");
         |                     ^^

      error: aborting due to 1 previous error
      ```
    ]

    `rustlings run intro2` #footnote[
    `intro2` 为该练习的名称，通常为路径最后的无 `.rs` 后缀的文件名。也可通过
    `rustlings list` 查看。
    ]

    #block_code_in_one_page(12pt)[
      ```rust
      ⠙ Compiling exercises/intro/intro2.rs...
      Hello!
      ✅ Successfully ran exercises/intro/intro2.rs
      ```
    ]
  ]
]
