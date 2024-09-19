#import "../utils.typ": *

#let usage = [
  == 使用 rustlings CLI： `run`

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
    #c[rustlings run intro2]
    #block_code_in_one_page(12pt)[
      ```rust
      ⠙ Compiling exercises/intro/intro2.rs...
      Hello!

      ✅ Successfully ran exercises/intro/intro2.rs
      ```
    ]
  ]
]