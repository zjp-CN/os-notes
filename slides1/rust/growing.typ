#import "../utils.typ": *

#let content = [

  == Rust 在不断完善和丰富

  #v(10pt)

  #block_help[每 6 周发布一个次要版本 `1.x => 1.(x+1)`, 不定期发布补丁版本。]

  - Rust 官方博客会介绍每个版本中的功能变化，比如最近几个版本公告

    - (2024-09-05) #link("https://blog.rust-lang.org/2024/09/05/Rust-1.81.0.html", "Announcing Rust 1.81.0")
    - (2024-08-08) #link("https://blog.rust-lang.org/2024/08/08/Rust-1.80.1.html", "Announcing Rust 1.80.1")
    - (2024-07-25) #link("https://blog.rust-lang.org/2024/07/25/Rust-1.80.0.html", "Announcing Rust 1.80.0")

  - Rust 版本功能变化一览：#link("https://releases.rs/", "release.rs")


  #v(10pt)

  #block(stroke: black, inset: 18pt)[
    #text(size: 8.5pt)[
      在语义版本 (Semver) 和 Rust 中，`major.minor.patch` 的具体含义

      - 递增 `major` 版本，意味着完全不兼容的改动：Rust 不会存在 2.0 版本
      - 递增 `minor` 版本，意味着向后兼容地增加功能：Rust 的常态，增加新功能和修复各种错误
      - 递增 `patch` 版本，意味着向后兼容地修复错误：不频繁，主要修复次要版本带来的回归
    ]
  ]

  #pagebreak()

  #emph[
    #text(size: 18pt)[ Stability Without Stagnation]
  ]

  每 3 年发布一个版次 (
  #link("https://doc.rust-lang.org/stable/edition-guide", "Edition Guide")
  )，今年将发布 #context { link(locate(<rust-edition-2024>), "Edition 2024") }。

  版次实质上是一种完全不兼容的改动，但缓和了摩擦。

  #quote(src: (
    "https://doc.rust-lang.org/stable/edition-guide/editions/index.html",
    "Edition Guide: What are Editions?",
  ))[
    #set list(spacing: 18pt)

    - 所有 Rust 代码，无论什么版次，*最终都将编译为编译器中的相同内部表示*
    - 一个版次中的 crate 必须与使用其他版次编译的 crate 无缝相互操作
    - 每个 crate 都可以独立决定何时迁移到新版次：这个决定是“私有的”，它不会影响生态系统中的其他 crates
  ]

  == Rust 语言和项目运作的理念

  #quote(
    src: (
      "https://blog.rust-lang.org/inside-rust/2022/04/19/imposter-syndrome.html",
      text(size: 8pt)[Rust Blog: Imposter Syndrome],
    ),
    size: 8pt,
  )[

    使 Rust 项目如此出色的原因不是几个多产的贡献者独自翻山越岭，

    而是每个人的共同努力将我们带到了今天的位置。

    我们都会犯错。

    该项目有一层#footnote[
      #set text(size: 5pt)
      任何不可逆的改动（例如稳定化）都需要相关团队中的几乎每个人都批准，还需要团队中没有人员提出异议。
    ]又一层 #footnote[
      #set text(size: 5pt)
      我们在所有代码改动进入稳定版之前，使用 #link("https://github.com/rust-lang/crater", "crater")
      来仔细检查它们，并小心地快速恢复在 crater 或夜间导致问题的代码。
    ]的保护措施，以确保我们有机会在它们影响使用者之前捕获并修复它们。

    这些事情是不可避免的，意料之中的，老实说没问题的！

    #v(9pt)
    这是 Rust 语言和 Rust 项目最基本的理念：

    我们认为仅仅让不犯错误的人来构建健壮的系统是不够的；

    我们认为_最好提供工具和流程来发现和防止错误_。

    我们的座右铭是“一种让每个人都能构建可靠和高效的软件的语言”，这不是偶然。

    #emph[
      #set text(size: 9pt)
      我们希望人们在 Rust 项目中，即使没有 100% 的信心，

      但依然感觉有能力去做出改变、犯错、学习和成长。
    ]

    这就是我们所有人走到今天的方式！

  ]
]

