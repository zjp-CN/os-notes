#let github_ssh = [
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

]