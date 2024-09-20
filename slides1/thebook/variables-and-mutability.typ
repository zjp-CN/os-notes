#import "../utils.typ": *

#let rust(code, out: none, size: 8pt, highlights: none) = {
  show raw.where(block: true): it => text(size, it)
  set block(breakable: false, spacing: 8pt)

  codly(
    languages: (
      rust: (
        name: "Rust",
        icon: text(font: "tabler-icons", "\u{fa53}"),
        color: rgb("#CE412B"),
      ),
    ),
    zebra-fill: none,
    fill: codeblock_bg,
    number-format: it => [ #text(fill: gray, str(it)) ],
    number-align: right + horizon,
  )

  codly(highlights: highlights) // 只高亮源代码
  raw(code, lang: "rust", block: true)

  if out != none {
    codly(highlights: none)
    raw(out, lang: "rust", block: true)
  }
}

#let content = [

  == 变量和可变性

  #rust(
    "fn main() {
  let x = 5;
  println!(\"The value of x is: {x}\");
  x = 6;
  println!(\"The value of x is: {x}\");
}",
    out: "$ cargo run
   Compiling variables v0.1.0 (file:///projects/variables)
error[E0384]: cannot assign twice to immutable variable `x`
 --> src/main.rs:4:5
  |
2 |     let x = 5;
  |         -
  |         |
  |         first assignment to `x`
  |         help: consider making this binding mutable: `mut x`
3 |     println!(\"The value of x is: {x}\");
4 |     x = 6;
  |     ^^^^^ cannot assign twice to immutable variable

For more information about this error, try `rustc --explain E0384`.
error: could not compile `variables` (bin \"variables\") due to 1 previous error",
    size: 6.5pt,
    highlights: (
      (
        line: 1,
        start: 4,
        end: 7,
        fill: red,
      ),
    ),
  )

  #rust(
    "fn main() {
    let mut x = 5;
    println!(\"The value of x is: {x}\");
    x = 6;
    println!(\"The value of x is: {x}\");
}",
    out: "$ cargo run
The value of x is: 5
The value of x is: 6",
    size: 9pt,
    highlights: (
      (
        line: 1,
        start: 5,
        end: 10,
        fill: green,
      ),
    ),
  )

]
