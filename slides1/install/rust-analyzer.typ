#import "../utils.typ": *

#let install = [

  
#v(20pt)
#block_help[
Rust-Analyzer 是 Rust 官方支持的 LSP 实现，支持在不同编辑器中提供一致的语言服务体验。安装和配置见 #link("https://rust-analyzer.github.io/manual.html")[RA 官方手册]。
]

#v(15pt)


- 在 VSCode 上，你只需要
  #link("https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer")[搜索和点击安装按钮]，就能直接工作。
  
- 对于 JetBrains 软件，比如 RustRover，则自行查看其官方文档说明。

- 在其他编辑器上，你需要仔细阅读上面的手册链接，比如通过
  `rustup component add rust-analyzer` 命令安装它，并安装相关的编辑器插件。

- 我是 NeoVim 的重度使用者，最近三年几乎每天都通过 NeoVim 编码。如果你想使用它的话，可以参考我的#link("https://github.com/zjp-CN/nvim-config")[配置文件]。

]