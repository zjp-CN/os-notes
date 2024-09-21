#import "utils.typ": *
#import "utils.typ" as u

#let _if = [

  === (1) `if` 和 `if else` 语句


  #rust("
if expr_bool { ... }

if expr_bool { A } else { B }
")

  其中 `expr_bool` 是一个值为 bool 类型的表达式。

  #v(10pt)

  #rust(
    "let number = 3;
if number < 5 {
    println!(\"condition was true\");
} else {
    println!(\"condition was false\");
}",
    out: "$ cargo run
condition was true",
  )

  #pagebreak()


  #rust(
    "
let number = 3;

if number {
    println!(\"number was three\");
}
",
    out: "
error[E0308]: mismatched types
 --> src/main.rs:4:8
  |
4 |     if number {
  |        ^^^^^^ expected `bool`, found integer
",
  )

  Rust 只有严格的 bool 值，所有不是 bool 值的表达式，都无法作为 `if` 条件。

  #pagebreak()
  _多条件的 `if else-if else` 语句_

  #rust(
    "
let number = 6;

if number % 4 == 0 {
    println!(\"number is divisible by 4\");
} else if number % 3 == 0 {
    println!(\"number is divisible by 3\");
} else if number % 2 == 0 {
    println!(\"number is divisible by 2\");
} else {
    println!(\"number is not divisible by 4, 3, or 2\");
}
",
    out: "$ cargo run
number is divisible by 3",
  )

  #pagebreak()

  _`if` 和 `if-else` 还可以作为表达式_

  #rust(
    "
let condition = true;
let number = if condition { 5 } else { 6 };

println!(\"The value of number is: {number}\");
",
    out: "$ cargo run
The value of number is: 5",
  )

  #pagebreak()
  _`if-else` 两个分支内返回的表达式必须具有相同的类型_

  #rust(
    "
let number = if condition { 5 } else { \"six\" };
",
    out: "$ cargo run
error[E0308]: `if` and `else` have incompatible types
 --> src/main.rs:4:44
  |
4 | let number = if condition { 5 } else { \"six\" };
  |                             -          ^^^^^ expected integer, found `&str`
  |                             |
  |                             expected because of this",
  )

]

#let _loop = [

  === (2) `loop` 循环语句

  #rust(
    "
loop {
    println!(\"again!\");
}
",
    out: "$ cargo run
again!
again!
again!
again!
^Cagain!",
  )

  #pagebreak()

  _`loop` 也是一种表达式_

  使用 `break` 语句从循环中返回一个值。

  #rust(
    "
let mut counter = 0;

let result = loop {
    counter += 1;

    if counter == 10 {
        break counter * 2;
    }
};

println!(\"The result is {result}\");
",
    out: "$ cargo run
The result is 20",
  )

  #pagebreak()
  _`loop label`_

  #grid(
    columns: (55fr, 25fr),
    rows: 1,
    gutter: 20pt,
    rust(
      "let mut count = 0;
'counting_up: loop {
    println!(\"count = {count}\");
    let mut remaining = 10;
    loop {
        println!(\"remaining = {remaining}\");
        if remaining == 9 {
            break;
        }
        if count == 2 {
            break 'counting_up;
        }
        remaining -= 1;
    }
    count += 1;
}
println!(\"End count = {count}\");",
      // highlights: ((line: 1, end: 12, fill: green),),
    ),
    rust(
      none,
      out: "
$ cargo run
count = 0
remaining = 10
remaining = 9
count = 1
remaining = 10
remaining = 9
count = 2
remaining = 10
End count = 2
",
    ),
  )

]

#let _while = [

  === (3) `while` 条件语句

  #rust("
while expr { ... }
")

  #v(20pt)
  #grid(
    columns: (6fr, 4fr),
    rows: 1,
    gutter: 20pt,
    rust("
let a = [10, 20, 30, 40, 50];
let mut index = 0;

while index < 5 {
    println!(\"the value is: {}\", a[index]);

    index += 1;
}
"),
    rust(
      none,
      out: "$ cargo run
the value is: 10
the value is: 20
the value is: 30
the value is: 40
the value is: 50",
    ),
  )

  #pagebreak()
  === (4) `for` 语句迭代元素

  #rust("
for ele in collection { ... }
")

  #v(20pt)
  #grid(
    columns: (6fr, 4fr),
    rows: 1,
    gutter: 20pt,
    rust("
let a = [10, 20, 30, 40, 50];

for element in a {
    println!(\"the value is: {element}\");
}
"),
    rust(
      none,
      out: "$ cargo run
the value is: 10
the value is: 20
the value is: 30
the value is: 40",
    ),
  )

]

#let content = [

  == 控制流语句

  #_if
  #pagebreak()
  #_loop
  #pagebreak()
  #_while

]
