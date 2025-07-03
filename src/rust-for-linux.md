# Rust for Linux

## 安装

```bash
# 1.1 从 https://mirrors.edge.kernel.org/pub/tools/llvm/rust/ 上获取最新的 LLVM 和 Rust 预编译的工具链
wget https://mirrors.edge.kernel.org/pub/tools/llvm/rust/files/llvm-20.1.5-rust-1.87.0-aarch64.tar.gz
# 1.2 解压
ouch d llvm-20.1.5-rust-1.87.0-aarch64.tar.gz

```

## 调试

`make -n` 会打印出需要执行的命令，也就是 make 函数调用和宏展开之后的样子，非常适合查看生成的最终命令：

```bash
make -C linux LLVM=1 -j$(($(nproc) + 1)) RUSTC=$(which safety-tool-rfl) -n $BUILD_TARGETS

# 示例输出
set -e;  echo '  RUSTC L rust/bindings.o';   trap 'rm -f rust/bindings.o; trap - HUP; kill -s HUP $$' HUP;  trap 'rm -f rust/bindings.o; trap 
- INT; kill -s INT $$' INT;  trap 'rm -f rust/bindings.o; trap - QUIT; kill -s QUIT $$' QUIT;  trap 'rm -f rust/bindings.o; trap - TERM; kill 
-s TERM $$' TERM;  trap 'rm -f rust/bindings.o; trap - PIPE; kill -s PIPE $$' PIPE; OBJTREE=/home/gh-zjp-CN/tag-std/linux /home/gh-zjp-CN/.car
go/bin/safety-tool-rfl --edition=2021 -Zbinary_dep_depinfo=y -Astable_features -Dnon_ascii_idents -Dunsafe_op_in_unsafe_fn -Wmissing_docs -Wru
st_2018_idioms -Wunreachable_pub -Wclippy::all -Wclippy::as_ptr_cast_mut -Wclippy::as_underscore -Wclippy::cast_lossless -Wclippy::ignored_uni
t_patterns -Wclippy::mut_mut -Wclippy::needless_bitwise_bool -Aclippy::needless_lifetimes -Wclippy::no_mangle_with_rust_abi -Wclippy::ptr_as_p
tr -Wclippy::ptr_cast_constness -Wclippy::ref_as_ptr -Wclippy::undocumented_unsafe_blocks -Wclippy::unnecessary_safety_comment -Wclippy::unnec
essary_safety_doc -Wrustdoc::missing_crate_level_docs -Wrustdoc::unescaped_backticks -Cpanic=abort -Cembed-bitcode=n -Clto=n -Cforce-unwind-ta
bles=n -Ccodegen-units=1 -Csymbol-mangling-version=v0 -Crelocation-model=static -Zfunction-sections=n -Wclippy::float_arithmetic --target=aarc
h64-unknown-none-softfloat -Cforce-unwind-tables=n -Zbranch-protection=bti,pac-ret -Copt-level=2 -Cdebug-assertions=n -Coverflow-checks=y -Cfo
rce-frame-pointers=y -Cdebuginfo=1 @./include/generated/rustc_cfg --extern ffi --emit=dep-info=rust/.bindings.o.d --emit=obj=rust/bindings.o -
-emit=metadata=rust/libbindings.rmeta --crate-type rlib -L./rust --crate-name bindings rust/bindings/lib.rs --sysroot=/dev/null  ; ./scripts/b
asic/fixdep rust/.bindings.o.d rust/bindings.o 'OBJTREE=/home/gh-zjp-CN/tag-std/linux /home/gh-zjp-CN/.cargo/bin/safety-tool-rfl --edition=202
1 -Zbinary_dep_depinfo=y -Astable_features -Dnon_ascii_idents -Dunsafe_op_in_unsafe_fn -Wmissing_docs -Wrust_2018_idioms -Wunreachable_pub -Wc
lippy::all -Wclippy::as_ptr_cast_mut -Wclippy::as_underscore -Wclippy::cast_lossless -Wclippy::ignored_unit_patterns -Wclippy::mut_mut -Wclipp
y::needless_bitwise_bool -Aclippy::needless_lifetimes -Wclippy::no_mangle_with_rust_abi -Wclippy::ptr_as_ptr -Wclippy::ptr_cast_constness -Wcl
ippy::ref_as_ptr -Wclippy::undocumented_unsafe_blocks -Wclippy::unnecessary_safety_comment -Wclippy::unnecessary_safety_doc -Wrustdoc::missing
_crate_level_docs -Wrustdoc::unescaped_backticks -Cpanic=abort -Cembed-bitcode=n -Clto=n -Cforce-unwind-tables=n -Ccodegen-units=1 -Csymbol-ma
ngling-version=v0 -Crelocation-model=static -Zfunction-sections=n -Wclippy::float_arithmetic --target=aarch64-unknown-none-softfloat -Cforce-u
nwind-tables=n -Zbranch-protection=bti,pac-ret -Copt-level=2 -Cdebug-assertions=n -Coverflow-checks=y -Cforce-frame-pointers=y -Cdebuginfo=1 @
./include/generated/rustc_cfg --extern ffi --emit=dep-info=rust/.bindings.o.d --emit=obj=rust/bindings.o --emit=metadata=rust/libbindings.rmet
a --crate-type rlib -L./rust --crate-name bindings rust/bindings/lib.rs --sysroot=/dev/null  ' > rust/.bindings.o.cmd; rm -f rust/.bindings.o.
d
:
  RUSTC L rust/bindings.o
```

`make -d` 会显示大量的调试信息，包括每个目标的依赖关系和正在执行的命令：

```bash
...
No recipe for '/home/gh-zjp-CN/tag-std/linux/rust/kernel/generated_arch_static_branch_asm.rs' and no prerequisites actually changed.
No need to remake target '/home/gh-zjp-CN/tag-std/linux/rust/kernel/generated_arch_static_branch_asm.rs'.
Pruning file '/home/gh-zjp-CN/tag-std/linux/rust/libcore.rmeta'.
Pruning file '/home/gh-zjp-CN/tag-std/linux/rust/libffi.rmeta'.
Pruning file '/home/gh-zjp-CN/tag-std/linux/rust/libcompiler_builtins.rmeta'.
Considering target file '/home/gh-zjp-CN/tag-std/linux/rust/libpin_init.rmeta'.
 Looking for an implicit rule for '/home/gh-zjp-CN/tag-std/linux/rust/libpin_init.rmeta'.
 No implicit rule found for '/home/gh-zjp-CN/tag-std/linux/rust/libpin_init.rmeta'.
 Finished prerequisites of target file '/home/gh-zjp-CN/tag-std/linux/rust/libpin_init.rmeta'.
No recipe for '/home/gh-zjp-CN/tag-std/linux/rust/libpin_init.rmeta' and no prerequisites actually changed.
No need to remake target '/home/gh-zjp-CN/tag-std/linux/rust/libpin_init.rmeta'.
Pruning file '/home/gh-zjp-CN/tag-std/safety-tool/target/safety-tool/lib/libsafety_macro.so'.
Pruning file '/home/gh-zjp-CN/tag-std/linux/rust/libmacros.so'.
Pruning file '/home/gh-zjp-CN/tag-std/linux/rust/libpin_init_internal.so'.
Considering target file '/home/gh-zjp-CN/tag-std/linux/rust/libbuild_error.rmeta'.
 Looking for an implicit rule for '/home/gh-zjp-CN/tag-std/linux/rust/libbuild_error.rmeta'.
 No implicit rule found for '/home/gh-zjp-CN/tag-std/linux/rust/libbuild_error.rmeta'.
 Finished prerequisites of target file '/home/gh-zjp-CN/tag-std/linux/rust/libbuild_error.rmeta'.
No recipe for '/home/gh-zjp-CN/tag-std/linux/rust/libbuild_error.rmeta' and no prerequisites actually changed.
No need to remake target '/home/gh-zjp-CN/tag-std/linux/rust/libbuild_error.rmeta'.
Considering target file '/home/gh-zjp-CN/tag-std/linux/rust/libbindings.rmeta'.
 Looking for an implicit rule for '/home/gh-zjp-CN/tag-std/linux/rust/libbindings.rmeta'.
 No implicit rule found for '/home/gh-zjp-CN/tag-std/linux/rust/libbindings.rmeta'.
 Finished prerequisites of target file '/home/gh-zjp-CN/tag-std/linux/rust/libbindings.rmeta'.
...
```

## 拓展阅读

* 2025.06 [A Newbie's First Contribution to (Rust for) Linux](https://blog.buenzli.dev/rust-for-linux-first-contrib/)
