#import "utils.typ": *

#let content = [

  == 代码和文档注释

  _Rust 代码注释_

  #rust("
// A normal comment.
")
  #rust("
/*
 A block comment.
*/

let var /*: Type */ = ' ';")

  #pagebreak()
  _Cargo 文档注释_

  #rust("
/// Doc comment for an item.
pub fn func() {}

//! # My Crate
//!
//! `my_crate` is a collection of utilities to make performing certain
//! calculations more convenient.
")

  Or in attribute form:

  #rust("
#[doc=\"...\"]

#![doc=\"...\"]
")

  #align(right)[
    Refer to #link(
    "https://doc.rust-lang.org/reference/comments.html",
    "Reference: Comments"
  )
  ]

]
