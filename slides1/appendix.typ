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


  // == bonus
  //
  // #v(15pt)
  // 这是可讲可不讲的部分，如果课程时间不充裕则不讲。
  //
  // #set list(spacing: 20pt)
  // #v(20pt)
  //
  // - 我的 Rust 入门经验和阅读清单：https://www.yuque.com/zhoujiping/programming/rust-materials #footnote[
  //     主要在 2021 年更新，没收录在这之后的入门材料。
  //   ]
  //
  // - 演示如何查看训练营官网的往届课程资料


]
