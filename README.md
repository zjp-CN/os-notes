# 开源操作系统训练营笔记

时间：2024 年 4 月至 6 月

项目结构

```text
.
├── src (笔记)
├── cortex-m-quickstart (submodule)
├── embassy (submodule)
├── embassy-usage (submodule)
├── green-thread (submodule)
└─┬ rCore-Tutorial-Code-2024S-embassy (submodule)
  ├── user (submodule)
  ├── ...                                             
```

如果要获取 cortex-m-quickstart、rCore-embassy 子模块在内的项目，使用以下命令

```console
git clone --recurse-submodules https://github.com/zjp-CN/os-notes.git
```

这些子模块内的代码都修改过；如果只获取单独的子模块，见 [.gitmodules](https://github.com/zjp-CN/os-notes/blob/main/.gitmodules) 内的仓库 url。
