#import "../utils.typ": *

#let content = [

  == Rust 的愿景

  #v(45pt)
  #let slogan = [
    #quote(src: (
      "https://www.rust-lang.org/",
      "rust-lang.org",
    ))[
      #let size = 14pt
      #let eve(a) = {
        text(fill: rgb("deea3a"), weight: "bold", size, a)
      }
      #let r(a) = {
        text(fill: rgb("7CFC00"), weight: "bold", size, a)
      }
      #let eff(a) = {
        text(fill: rgb("FFA07A"), weight: "bold", size, a)
      }

      Empowering #eve[everyone] to build #r[reliable] and #eff[efficient] software.

      #text(fill: white)[
        让 #eve[每个人] 都能构建 #r[可靠] 和 #eff[高效] 的软件。
      ]

    ]
  ]

  #slogan
  #pagebreak()
  #slogan
  #text(size: 10.3pt)[
    #set list(tight: false)

    - *everyone*：

      - 无关国籍、信仰、年龄、性别、知识水平、教育背景...
      - 具有全球、开放和包容的社区支持，任何人可以自由、公平进出

    - *reliable*：

      - 通过所有权模型和丰富的类型系统，在编译期间消除诸多错误，*保证内存和线程安全*
      - 一流的包管理工具 Cargo、良好的文档以及友好的编译器错误报告

    - *efficient*：

      - 无运行时和垃圾收集器，*内存高效*
      - 可生成高度优化的代码，*运行高效*
  ]

  == 2023 年官方统计调查结果

  #set page(footer: none)

  #figure(
    image("../img/why-you-use-rust-at-work.svg"),
    caption: link(
      "https://blog.rust-lang.org/2024/02/19/2023-Rust-Annual-Survey-2023-results.html",
      "2023 年 Rust 官方年度统计调查：为什么在工作中使用 Rust",
    ),
  )

  #figure(
    image("../img/technology-domains.png"),
    caption: link(
      "https://blog.rust-lang.org/2024/02/19/2023-Rust-Annual-Survey-2023-results.html",
      "2023 年 Rust 官方年度统计调查：使用者来自哪些科技领域",
    ),
  )

]
