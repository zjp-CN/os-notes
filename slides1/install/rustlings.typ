#import "../utils.typ": *

#let install = [
  == 安装 rustlings CLI

  #align(center)[
    #v(20pt)

    #block_help[#emph[
        强烈建议首先阅读仓库中的\
        `README` 和 `exercises/README.md`#footnote[
          该文档包含每组练习与 《#link("https://doc.rust-lang.org/stable/book/","The Rust Programming Language")》对应的章节。
        ]，\
        尤其是训练营相关的中文部分。
      ]]

    #v(12pt)

    ```bash
    # 进入本地仓库目录
    cd rust-rustlings-2024-*

    # 确保 Rust 工具链安装成功并且可用

    # 源码编译并安装 rustlings 可执行文件到 ~/.cargo/bin 目录
    cargo install --force --path .
    ```
  ]

  == exercises 与 the Book 对应的章节

  #block_code_in_one_page(11pt)[
    ```bash
    $ cat exercises/README.md
    # Exercise to Book Chapter mapping

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

  == `rustlings --help`

  #block_code_in_one_page(11pt)[
    #set block(width: 103%)
    ```bash
    $ rustlings --help
    Usage: rustlings [--nocapture] [-v] [<command>] [<args>]

    Rustlings is a collection of small exercises to get you used to writing and reading Rust code

    Options:
      --nocapture       show outputs from the test exercises
      -v, --version     show the executable version
      --help            display usage information

    Commands:
      verify            Verifies all exercises according to the recommended order
      watch             Reruns `verify` when files were edited
      run               Runs/Tests a single exercise
      reset             Resets a single exercise using "git stash -- <filename>"
      hint              Returns a hint for the given exercise
      list              Lists the exercises available in Rustlings
      lsp               Enable rust-analyzer for exercises
      cicvverify        cicvverify
    ```
  ]
]
