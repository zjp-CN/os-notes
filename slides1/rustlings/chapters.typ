#import "../utils.typ": *

#let content = [

  == `exercises/README.md`

  该文档包含每组练习与 《#link("https://doc.rust-lang.org/stable/book/", "The Rust Programming Language")》对应的章节。

  #block_code_in_one_page(11pt)[
    ```bash
    $ cat exercises/README.md

    | Exercise         | Book Chapter |  | Exercise         | Book Chapter |
    | ---------------- | ------------ |  | ---------------- | ------------ |
    | variables        | §3.1         |  | generics         | §10          |
    | functions        | §3.3         |  | options          | §10.1        |
    | if               | §3.5         |  | traits           | §10.2        |
    | primitive_types  | §3.2, §4.3   |  | tests            | §11.1        |
    | vecs             | §8.1         |  | lifetimes        | §10.3        |
    | move_semantics   | §4.1-2       |  | iterators        | §13.2-4      |
    | structs          | §5.1, §5.3   |  | threads          | §16.1-3      |
    | enums            | §6, §18.3    |  | smart_pointers   | §15, §16.3   |
    | strings          | §8.2         |  | macros           | §19.6        |
    | modules          | §7           |  | clippy           | §21.4        |
    | hashmaps         | §8.3         |  | conversions      | n/a          |
    | error_handling   | §9           |
    ```
  ]

  注意：训练营增加的额外的算法题 `exercises/algorithm` 与 the Book
  无直接对应的章节。因此除了需要裸指针的基础知识，还需要相关的算法知识。

]
