#import "../utils.typ": *

#let content = [


  == `unsafe` 关键字

  #show table.cell: it => {
    if it.y == 0 {
      align(center + horizon, text(weight: "bold", fill: orange, it))
    } else {
      it
    }
  }
  #table(
    columns: (144pt, 152pt, auto),
    inset: 7pt,
    align: (horizon, horizon, center + horizon),
    table.header(
      [`unsafe` 代码],
      [功能],
      [谁保证安全条件],
    ),

    [
      - `unsafe fn`
      - `unsafe trait`
    ],
    [标识 *定义* 额外的安全条件],
    [该代码的*使用者*],

    [
      - `unsafe {}`
      - `unsafe impl`
      - `unsafe fn` without `unsafe_op_in_unsafe_fn`
    ],
    [标识 *满足* 额外的安全条件],
    [该代码的*编写者*],
  )

  #quote(src: (
    "https://doc.rust-lang.org/reference/unsafe-keyword.html",
    "Reference: The unsafe keyword",
  ))[
    #set block(spacing: 12pt)

    Unsafe functions (`unsafe fn`) are functions that are not safe in all contexts and/or for all possible inputs.

    We say they have extra safety conditions, which are requirements that must be upheld by all callers and that the compiler does not check.

  ]

  == Rust 中的未定义的行为 (UB)

  <rust-ub>

  #quote(
    src: (
      "https://doc.rust-lang.org/reference/unsafe-keyword.html",
      "Reference: Behavior considered undefined",
    ),
    width: 105%,
  )[
    #set block(spacing: 15pt)
    #set enum(spacing: 10pt)
    #set text(size: 8.8pt)

    + Data races.

    + Accessing (loading from or storing to) a place that is dangling or based on a misaligned pointer.

    + Performing a place projection that violates the requirements of in-bounds pointer arithmetic.

    + Breaking the pointer *aliasing rules*.

    + Mutating immutable bytes.

    + Invoking undefined behavior via compiler intrinsics.

    + Executing code compiled with platform features that the current platform does not support, except if the platform explicitly documents this to be safe.

    + Calling a function with the wrong call ABI or unwinding from a function with the wrong unwind ABI.

    + Producing an invalid value, even in private fields and locals.

    + Incorrect use of inline assembly.

    + In const context: transmuting or otherwise reinterpreting a pointer into some allocated object as a non-pointer type (such as integers).

  ]


  == Rust 中不被视为 Unsafe 的行为

  #v(20pt)
  #quote(src: (
    "https://doc.rust-lang.org/reference/unsafe-keyword.html",
    "Reference: Behavior not considered unsafe",
  ))[

    + Deadlocks

    + Leaks of memory and other resources

    + Exiting without calling destructors

    + Exposing randomized base addresses through pointer leaks

    + Integer overflow

    + Logic errors

  ]


  == Rust 2024 Edition 🚧

  <rust-edition-2024>

  #quote(src: (
    "https://doc.rust-lang.org/stable/edition-guide/rust-2024/index.html",
    "The Rust Edition Guide: Rust 2024",
  ))[
    + Additions to the prelude
    + Add IntoIterator for `Box<[T]>`
    + unsafe_op_in_unsafe_fn warning
    + RPIT lifetime capture
    + Disallow references to static mut
    + Cargo: Remove implicit features
    + Cargo: Table and key name consistency
    + Cargo: Reject unused inherited default-features
    + Rustfmt: Combine all delimited exprs as last argument
    + gen keyword
    + Macro fragment specifiers
    + Never type fallback change
    + unsafe extern blocks
    + Unsafe attributes
  ]


]
