#import "../utils.typ": *

#let content = [

  == Rust 在不断完善和丰富

  #v(10pt)

  + 6 周发布一个次要版本 #footnote[
      在语义版本 (Semver) 和 Rust 中，`major.minor.patch` 的具体含义
      - 递增 major 版本，意味着完全不兼容的改动：Rust 不会存在 2.0 版本
      - 递增 minor 版本，意味着向后兼容地增加功能：这是 Rust 的常态
      - 递增 patch 版本，意味着向后兼容地修复错误：不频繁，因为 Rust 的次要版本包含了积极修复的各种错误
    ]
    `1.x => 1.(x+1)`, 不定期发布补丁版本

    - Rust 官方博客会介绍每个版本中的功能变化，比如最近几个版本公告

      - (2024-09-05) #link("https://blog.rust-lang.org/2024/09/05/Rust-1.81.0.html", "Announcing Rust 1.81.0")
      - (2024-08-08) #link("https://blog.rust-lang.org/2024/08/08/Rust-1.80.1.html", "Announcing Rust 1.80.1")
      - (2024-07-25) #link("https://blog.rust-lang.org/2024/08/08/Rust-1.80.0.html", "Rust 1.80.0")

    - Rust 版本功能变化一览：#link("https://releases.rs/", "release.rs")

  + 3 年发布一个版次，见 #link("https://doc.rust-lang.org/stable/edition-guide", "Edition Guide")

    - 今年将发布 #context { link(locate(<rust-edition-2024>), "Edition 2024") }

    - 在我看来，版次实质上是一种完全不兼容的改动，但缓和了摩擦。



  https://blog.rust-lang.org/inside-rust/2022/04/19/imposter-syndrome.html
]

