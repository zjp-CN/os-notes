#import "utils.typ": *

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
    display-name: true,
    display-icon: true,
    zebra-fill: none,
    fill: codeblock_bg,
    number-format: it => [ #text(fill: gray, str(it)) ],
    number-align: right + horizon,
  )

  codly(highlights: highlights) // 只高亮源代码
  raw(code, lang: "rust", block: true)

  if out != none {
    codly(
      highlights: none,
      fill: rgb("F6F7FC"),
      display-name: false,
      display-icon: false,
    )
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
  #btitle[修改变量的值，需要 #c[mut] 关键字]

  #pagebreak()

  #rust(
    "fn main() {
    let x = 5;
    let x = x + 1;
    {
        let x = x * 2;
        println!(\"The value of x in the inner scope is: {x}\");
    }
    println!(\"The value of x is: {x}\");
}",
    out: "$ cargo run
The value of x in the inner scope is: 12
The value of x is: 6",
    highlights: (
      (
        line: 2,
        start: 5,
        end: 10,
        fill: green,
      ),
      (
        line: 4,
        start: 9,
        end: 13,
        fill: green,
      ),
    ),
  )
  #btitle[Shadowing & Scope]

  #rust(
    "fn main() {
    let mut spaces = \"   \";
    spaces = spaces.len();
}",
    out: "$ cargo run
   Compiling variables v0.1.0 (file:///projects/variables)
error[E0308]: mismatched types
 --> src/main.rs:3:14
  |
2 |     let mut spaces = \"   \";
  |                      ----- expected due to this value
3 |     spaces = spaces.len();
  |              ^^^^^^^^^^^^ expected `&str`, found `usize`

For more information about this error, try `rustc --explain E0308`.
error: could not compile `variables` (bin \"variables\") due to 1 previous error",
    size: 7.2pt,
    highlights: (
      (
        line: 1,
        start: 5,
        end: 5,
        fill: red,
      ),
      (
        line: 2,
        start: 8,
        end: 11,
        fill: red,
      ),
    ),
  )
  #btitle[
    #set text(size: 9pt)
    变量的类型是静态确定的；#c[mut] 只能修改同类型的值，不能修改成不同类型的值。
  ]

  #rust(
    "fn main() {
    let spaces = \"   \";
    let spaces = spaces.len();
} // fine 🙂",
    size: 10pt,
    highlights: (
      (
        line: 1,
        start: 5,
        end: 9,
        fill: green,
      ),
      (
        line: 2,
        start: 5,
        end: 9,
        fill: green,
      ),
    ),
  )

  #btitle[
    利用 Shadowing 重新使用这个变量名
  ]


]
