#import "utils.typ": *

#let rustlings = [
== Rustlings：进入 Github 课堂

#let rustings_classroom = [
#link("https://classroom.github.com/assignment-invitations/1cefce5432c3fb9693ac4eb2883926f7")[👉 进入课堂]
]

#figure(
  image("img/rustlings-classroom.png", height: 85%),
  caption: [#rustings_classroom]
)

== Rustlings：课堂使用流程

#let rustings_rank(title) = [
#link("https://opencamp.cn/os2edu/camp/2024fall/stage/1?tab=rank")[#title]
#todo
]

#v(2pt)

#set enum(numbering: "1.a)", tight: false, spacing: 4%)

#enum[
  Github 授权登陆课堂；
][
  点击 https://github.com/ 开头的仓库链接，并把仓库克隆到本地 #footnote[
    这里为了免密码推送代码，使用了 SSH 协议的地址，因此你需要在 Github 上设置 SSH 密钥，见 #pageref(<github-ssh>)。
  ]；
```bash
git clone git@github.com:LearningOS/rust-rustlings-2024-*.git
```
][
  提交代码到该仓库；
```bash
git add . && git commit -m "done: exercise x" && git push
```
][
  每次推送到该仓库时，课堂系统会自动评分；
][
  在 Actions 标签页可以查看评分过程；
][
  查看评分结果：
  - 在远程仓库选择 gh-pages 分支：Action 完成时自动推送到该分支
  
  - 或者查看#rustings_rank("排行榜")：定时从 Github 拉取数据，因此会有延迟
]

== Rustlings：查看评分结果

#figure(
  image("img/rustlings-score.png", height: 75%),
  caption: [ 通过 gh-pages 分支查看评分结果 ]
)

== Rustlings：排行榜

#align(center)[
#block_note[
  #emph[注意：只有完成全部练习，达到 110 满分的同学才算完成第一阶段。]
]]

#figure(
  image("img/rustlings-rank.png", height: 78%),
  caption: [ 👉 #rustings_rank("第一阶段 Rustlings 完成情况排行榜")]
)
]