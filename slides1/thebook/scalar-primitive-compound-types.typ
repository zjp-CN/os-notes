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

#let tuple = [

  _Tuple_

  #rust("let tup /*: (i32, f64, u8) */ = (500, 6.4, 1);

// desctructure
let t1 = tup.0; // t1: i32
let t2 = tup.1; // t2: f64
let t3 = tup.1; // t3: u8
// or equivalently via pattern matching
let (t1, t2, t3) = tup;

// mutation
let mut tup = (500, 6.4, 1);
tup.0 = -500;
tup.1 = -6.4;
tup.2 = 255;")

]

#let array = [

  _Array_

  #rust("let a = [1, 2, 3, 4, 5];
let a: [i32; 5] = [1, 2, 3, 4, 5]; // explicit annotation

let a = [3; 5]; // same as let a = [3, 3, 3, 3, 3];

// indexing
let first = a[0];
let second = a[1];

// mutation
a[0] = 0;")

  #v(30pt)
  *Invalid Access in Array 👇*
  #pagebreak()

  *😀 Compile Time Error*

  #rust(
    "let a = [0];
a[1]; // compile time error",
    out: "error: this operation will panic at runtime
 --> src/lib.rs:2:1
  |
2 | a[1];
  | ^^^^ index out of bounds: the length is 1 but the index is 1
  |
  = note: `#[deny(unconditional_panic)]` on by default",
  )

  *💥 Runtime Panic*

  #rust(
    "let a = [0];
let idx = || 1;
a[idx()]; // runtime error",
    out: "thread 'main' panicked at src/main.rs:3:1:
index out of bounds: the len is 1 but the index is 1",
  )

]

#let content = [

  #show emph: it => text(fill: orange, it)

  == 基本数据类型

  === (1) Scalar Types

  #block(spacing: 15pt)[
    #bool
    #char
    #floating_points
  ]

  #pagebreak()
  #intergers

  === (2) Primitive Compound Types

  #tuple
  #pagebreak()
  #array

]
