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
  caption: [Github 设置 SSH ]
)

== 安装 Rust-Analyzer

<install-ra>

#import "install/rust-analyzer.typ"
#rust-analyzer.install

== bonus 

*可讲可不讲的部分* #footnote[如果课程时间已经太长，不讲]

- 我的 Rust 入门经验和阅读清单：https://www.yuque.com/zhoujiping/programming/rust-materials （主要在 2021 年更新，没收录在这之后的优秀入门材料）

- 演示如何查看训练营官网的往届课程资料


]