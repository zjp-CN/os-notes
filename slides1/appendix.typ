#import "utils.typ": *

#let content = [
  == Github 设置 SSH

  <github-ssh>

  #align(center)[
    ```bash
    # 生成新的 SSH 密钥对文件
    ssh-keygen -t ed25519 -C "your_email@example.com"

    # 将公钥内容复制到 Github 账号 Settings 的 SSH keys 中
    cat ~/.ssh/id_ed25519.pub
    ```
  ]

  #figure(
    image("img/github-ssh.png", height: 150pt, width: 330pt, fit: "stretch"),
    caption: [Github 设置 SSH ],
  )

  == Rustlings 的 exercises 与 the Book 对应的章节

  <rustlings-exercises-chapters>

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

  == 安装 Rust-Analyzer

  <install-ra>

  #import "install/rust-analyzer.typ"
  #rust-analyzer.install

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

  #quote[
    #set block(spacing: 12pt)

    Unsafe functions (`unsafe fn`) are functions that are not safe in all contexts and/or for all possible inputs.

    We say they have extra safety conditions, which are requirements that must be upheld by all callers and that the compiler does not check.

    #align(right)[
      src:
      #highlight(fill: orange, extent: 1.2pt)[
        #link("https://doc.rust-lang.org/reference/unsafe-keyword.html")[Reference: The unsafe keyword]
      ]
    ]
  ]


  == bonus#footnote[*这是可讲可不讲的部分*，如果课程时间不充裕则不讲。]

  #set list(spacing: 20pt)
  #v(20pt)

  - 我的 Rust 入门经验和阅读清单：https://www.yuque.com/zhoujiping/programming/rust-materials #footnote[
      主要在 2021 年更新，没收录在这之后的优秀入门材料
    ]

  - 演示如何查看训练营官网的往届课程资料


]
