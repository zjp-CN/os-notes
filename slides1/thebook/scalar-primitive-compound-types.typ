#import "utils.typ": *

#let interger_types = [
  ==== Integers
  #table(
    align: center + horizon,
    columns: 3,
    table.header(
      [*Length*],
      [*Signed*],
      [*Unsigned*],
    ),

    [8-bit], [i8], [u8],
    [16-bit], [i16], [u16],
    [32-bit], [i32], [u32],
    [64-bit], [i64], [u64],
    [128-bit], [i128], [u128],
    [arch], [isize], [usize],
  )
]

#let integer_literals = [
  ==== Integers Literals
  #table(
    align: center + horizon,
    columns: 2,
    table.header(
      [*Number Literals*],
      [*Example*],
    ),

    [Decimal], [`10_000`],
    [Hex], [`0xff`],
    [Octal], [`0o77`],
    [Binary], [`0b1111_000`],
    [Byte (`u8` only)], [`b'A'`],
  )
]

#let integer_snip = [
  #rust(
    "let a = 65; // a: i32

// assign the same u8 value to a variable
let b: u8 = 65; // type annotation
let c = 65u8; // literal suffix

let a /*: u8*/ = b'A'; // a byte
println!(\"\
  hex: {a:#x}, \
  octal: {a:#o}, \
  binary: {a:#b}\"
);
// output:
// hex: 0x41, octal: 0o101, binary: 0b1000001",
    num: none,
  )
]

#let intergers = [
  #grid(
    columns: 2,
    rows: 2,
    gutter: 24pt,

    grid.cell(
      rowspan: 2,
      [
        #set text(size: 9pt)
        #interger_types #integer_literals
      ],
    ),
    grid.cell(rowspan: 2, align: horizon, integer_snip)
  )
]

#let content = [

  == 基本数据类型

  === Scalar Types

  Integers, floating-point numbers, Booleans, and characters.


  #pagebreak()
  #intergers

]
