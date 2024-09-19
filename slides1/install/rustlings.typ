#import "../utils.typ": *

#let install = [
  == 安装 rustlings CLI

  #align(center)[
    #v(30pt)

    #block_help[#emph[
        强烈建议首先阅读仓库中的 README 文档，\
        尤其是训练营相关的中文部分。
      ]]

    #v(20pt)

    ```bash
    # 进入本地仓库目录
    cd rust-rustlings-2024-*

    # 确保 Rust 工具链安装成功并且可用

    # 源码编译并安装 rustlings 可执行文件到 ~/.cargo/bin 目录
    cargo install --force --path .
    ```
  ]

  #pagebreak()
  #block_code_in_one_page(11pt)[#context {
      set block(width: 103%)
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
    }
  ]
]