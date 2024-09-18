#import "../utils.typ": *

#let usage = [
== 使用 rustlings CLI： `lsp`

到目前为止，我们还没有真正开始 Rust 编程，因为我们没有充分利用现代语言的 LSP，来获得#emph[代码补全、跳转定义、错误检测、代码导航、重构工具、代码格式化]等 IDE 级别的语言服务。

#block_help[
Rust-Analyzer 是 Rust 官方支持的 LSP 实现，支持在不同编辑器中提供一致的语言服务体验。安装和配置见 #link("https://rust-analyzer.github.io/manual.html")[RA 官方手册]。
]

#pagebreak()

```rust
Diagnostics:
This file is not included in any crates, so rust-analyzer can't offer IDE services.

If you're intentionally working on unowned files, you can silence this warning by adding "unlinked-file" to rustnalyzer.diagnostics.disabled in your settings. [unlinked-file]
```

#c[rustlings lsp] 生成 #link("https://rust-analyzer.github.io/manual.html#non-cargo-based-projects")[rust-project.json]，供 RA 识别 rustlings 的项目结构。

```rust
$ rustlings lsp
Determined toolchain: /root/.rustup/toolchains/nightly-x86_64-unknown-linux-gnu

Successfully generated rust-project.json
rust-analyzer will now parse exercises, restart your language server or editor
```


]