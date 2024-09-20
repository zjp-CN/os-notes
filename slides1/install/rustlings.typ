#import "../utils.typ": *

#let install = [
  == 安装 rustlings CLI

  #align(center)[
    #v(20pt)

    #block_help[#emph[
        强烈建议首先阅读仓库中的\
        `README.md` 和 `exercises/README.md`，\
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


]
