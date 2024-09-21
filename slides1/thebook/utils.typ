#import "../utils.typ": *

/// bottom title
#let btitle(content) = [
  #align(center)[
    #v(10pt)
    #text(weight: "bold", size: 16pt, content)
  ]
]

#let rust(
  code,
  out: none,
  size: 8pt,
  highlights: none,
  new_page: false,
  num: it => [ #text(fill: gray, str(it)) ],
  display-name: true,
  display-icon: true,
) = {
  show raw.where(block: true): it => text(size, it)
  set block(breakable: false, spacing: 8pt)

  codly(
    languages: (
      rust: (
        name: "Rust",
        icon: text(font: "tabler-icons", "\u{fa53}"),
        color: rgb("#CE412B"),
      ),
    ),
    display-name: display-name,
    display-icon: display-icon,
    zebra-fill: none,
    fill: codeblock_bg,
    number-format: num,
    number-align: if num == none {
      left
    } else {
      right + horizon
    },
  )

  if code != none {
    codly(highlights: highlights) // 只高亮源代码
    raw(code, lang: "rust", block: true)
  }

  if out != none {
    if new_page {
      pagebreak()
      codly(highlights: highlights) // 只高亮源代码
      raw(code, lang: "rust", block: true)
    }
    codly(
      highlights: none,
      fill: rgb("F6F7FC"),
      display-name: false,
      display-icon: false,
    )
    raw(out, lang: "rust", block: true)
  }
}

