#import "../utils.typ": *

#let rust(code, out: none, size: 7.5pt) = {
  show raw.where(block: true): it => text(size, it)
  set block(breakable: false, spacing: 0pt)

  raw(code, lang: "rust", block: true)

  if out != none {
    raw(out, lang: "rust", block: true)
  }
}

#let content = [

  == 变量和可变性

  // #codly-disable()
  // #codly-offset(offset: 5)



  #rust(
    "fn main() {
  let x = 5;
  println!(\"The value of x is: {x}\");
  x = 6;
  println!(\"The value of x is: {x}\");
}
",
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
error: could not compile `variables` (bin \"variables\") due to 1 previous error
",
  )

  #rust(
    "fn main() {
    let mut x = 5;
    println!(\"The value of x is: {x}\");
    x = 6;
    println!(\"The value of x is: {x}\");
}",
    out: "$ cargo run
   Compiling variables v0.1.0 (file:///projects/variables)
    Finished `dev` profile [unoptimized + debuginfo] target(s) in 0.30s
     Running `target/debug/variables`
The value of x is: 5
The value of x is: 6
",
    size: 9pt,
  )

]
