#import "utils.typ": *

#let content = [

  == 变量和可变性

  #let snip_print = "fn main() {
  let x = 5;
  println!(\"The value of x is: {x}\");
}"
  #let snip_out_print = "$ cargo run
The value of x is: 5"
  #rust(
    snip_print,
    size: 15pt,
    highlights: (
      (
        line: 1,
        start: 4,
        end: 20,
        fill: green,
      ),
    ),
  )
  #pagebreak()
  #rust(
    snip_print,
    size: 15pt,
    highlights: (
      (
        line: 2,
        start: 4,
        end: 40,
        fill: green,
      ),
    ),
  )
  #pagebreak()
  #let snip_format = "format!(\"Hello\");                 // => \"Hello\"
format!(\"Hello, {}!\", \"world\");   // => \"Hello, world!\"
format!(\"The number is {}\", 1);   // => \"The number is 1\"
format!(\"{:?}\", (3, 4));          // => \"(3, 4)\"
format!(\"{value}\", value = 4);    // => \"4\"

let people = \"Rustaceans\";
format!(\"Hello {people}!\");       // => \"Hello Rustaceans!\"

format!(\"{} {}\", 1, 2);           // => \"1 2\"
format!(\"{:04}\", 42);             // => \"0042\" with leading zeros
format!(\"{:#?}\", (100, 200));     // => \"(
                                  //       100,
                                  //       200,
                                  //     )\""
  #rust(snip_format)

  `format!` 官方文档： https://doc.rust-lang.org/std/fmt/index.html

  #link(
    "https://www.yuque.com/zhoujiping/programming/pygvaf#sUK2v",
    text[👉 我画的 `format!` 语法导图],
  )
  #pagebreak()
  #rust(
    snip_print,
    out: snip_out_print,
    size: 15pt,
  )
  #pagebreak()

  #rust(
    "fn main() {
  let x = 5;
  println!(\"The value of x is: {x}\");
  x = 6;
  println!(\"The value of x is: {x}\");
}",
    out: "$ cargo run
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

For more information about this error, try `rustc --explain E0384`.",
    size: 7pt,
    highlights: (
      (
        line: 1,
        start: 4,
        end: 7,
        fill: red,
      ),
      (
        line: 3,
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
