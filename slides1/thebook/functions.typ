#import "utils.typ": *

#let content = [

  == 函数

  _Define & Call a function_

  #rust(
    "fn main() {
    println!(\"Hello, world!\");

    another_function();
}

fn another_function() {
    println!(\"Another function.\");
}",
    out: "$ cargo run
Hello, world!
Another function.",
    highlights: (
      (line: 3, fill: green),
      (line: 6, fill: green),
    ),
  )

  #pagebreak()
  _Arguments_

  #rust(
    "fn main() {
    print_labeled_measurement(5, 'h');
}

fn print_labeled_measurement(value: i32, unit_label: char) {
    println!(\"The measurement is: {value}{unit_label}\");
}",
    out: "$ cargo run
The measurement is: 5h",
    highlights: (
      (line: 1, start: 31, end: 36, fill: green),
      (line: 4, start: 30, end: 55, fill: green),
    ),
  )

  #pagebreak()
  === Statements vs Expressions

  - *Statements*#footnote[
      Rust has two kinds of #link("https://doc.rust-lang.org/reference/statements.html", "statement"):
      declaration statements and expression statements.
    ] are instructions that perform some action and do not return a value.

  - *Expressions* evaluate to a resultant value.

    - #link(
        "https://doc.rust-lang.org/reference/expressions.html#expression-precedence",
        "📝 Operators and Expression precedence",
      )

  #pagebreak()
  _Return value_

  #rust(
    "fn plus_one(x: i32) -> i32 {
    x + 1
}",
    size: 11pt,
    highlights: (
      (line: 0, start: 21, end: 25, fill: green),
      (line: 1, fill: green),
    ),
  )

  //   #rust("fn plus_one(x: i32) -> i32 {
  //     x + 1; // 💥
  // }")

  #pagebreak()
  #rust(
    "fn plus_one(x: i32) -> i32 {
    x + 1; // the trailling semicolon makes it a statement
    // which does not return values

    // implicitly returns `()` as the return value
}",
    out: "error[E0308]: mismatched types
 --> src/main.rs:7:24
  |
7 | fn plus_one(x: i32) -> i32 {
  |    --------            ^^^ expected `i32`, found `()`
  |    |
  |    implicitly returns `()` as its body has no tail or `return` expression
8 |     x + 1;
  |          - help: remove this semicolon to return this value",
    highlights: (
      (line: 0, start: 21, end: 25, fill: green),
      (line: 1, fill: red),
    ),
  )

]
