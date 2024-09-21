#import "utils.typ": *

#let interger_types = [
  _Integers_
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
  _Integers Literals_
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
    grid.cell(
      rowspan: 2,
      align: horizon,
      [
        #integer_snip

        #v(2pt)
        #text(size: 8pt, fill: gray)[
          Literal Tokens: https://doc.rust-lang.org/reference/tokens.html
        ]
      ],
    )
  )
]

#let floating_points = [

  _Floating Points_

  #let t = [
    #table(
      align: center + horizon,
      columns: 2,
      table.header(
        [*Length*],
        [*Types*],
      ),

      [32-bit], [f32],
      [64-bit], [f64],
    )
  ]

  #let snip = [
    #rust("let a = 0.1;        // a: f64
let b = 12E+99_f64; // b: f64
let c = 0.1f32      // c: f32
let d: f32 = 0.2;   // d: f32")
  ]

  #grid(
    columns: 2,
    rows: 1,
    gutter: 24pt,
    t,
    grid.cell(align: horizon, snip),
  )

]

#let bool = [

  _bool_

  #let t = [
    #table(
      align: center + horizon,
      columns: 2,
      table.header(
        [*Value*],
        [*Bit Pattern*],
      ),

      [`false`], [`0x00`],
      [`true`], [`0x01`],
    )
  ]

  #let snip = [
    #rust("let x = false;
let y: bool = true;")

    #text(size: 6.9pt, style: "italic")[
      Note: It is undefined behavior for an object with the boolean type
      to have *any other* bit pattern.
    ]
  ]

  #grid(
    columns: 2,
    rows: 1,
    gutter: 5pt,
    t,
    grid.cell(align: horizon, snip),
  )

]

#let char = [

  _char_

  #let snip = [
    #rust(
      "let ch = 'z'; let z: char = 'ℤ'; let emoji = '😻';",
      display-name: false,
      display-icon: false,
    )
  ]

  #grid(
    columns: (3fr, 7fr),
    rows: 1,
    gutter: 5pt,
    text(size: 10pt)[
      - 4 bytes in size
      - a Unicode Scalar Value
    ],
    grid.cell(align: horizon, snip),
  )
]

#let content = [

  #show emph: it => text(fill: orange, it)

  == 基本数据类型

  === Scalar Types

  #block(spacing: 15pt)[
    #bool
    #char
    #floating_points
  ]

  #pagebreak()
  #intergers

]
