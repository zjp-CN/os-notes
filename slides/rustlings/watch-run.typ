#import "../utils.typ": *

#let usage = [
== 使用 rustlings CLI： `watch` 和 `run`

#block_code_in_one_page(12pt)[
```rust
Progress: [--------------------------------------------------] 0/110
⚠️  Compiling of exercises/intro/intro2.rs failed! Please try again. Here's the output:

error: 1 positional argument in format string, but no arguments were given
  --> exercises/intro/intro2.rs:11:21
   |
11 |     println!("Hello {}!");
   |                     ^^

error: aborting due to 1 previous error

Welcome to watch mode! You can type 'help' to get an overview of the commands you can use here.
```
]
#align(center)[#c[rustlings watch]]

#pagebreak()

#align(center)[
#block_code_in_one_page(12pt)[
```rust
⚠️  Compilation of exercises/intro/intro2.rs failed!, Compiler error message:

error: 1 positional argument in format string, but no arguments were given
  --> exercises/intro/intro2.rs:11:21
   |
11 |     println!("Hello {}!");
   |                     ^^

error: aborting due to 1 previous error
```
]
#c[rustlings run intro2]
#block_code_in_one_page(12pt)[
```rust
⠙ Compiling exercises/intro/intro2.rs...
Hello!

✅ Successfully ran exercises/intro/intro2.rs
```
]

#pagebreak()
#block_code_in_one_page(9pt)[
```
Progress: [------------------------------------------------------------] 0/110
⠉ Compiling exercises/intro/intro2.rs...
✅ Successfully ran exercises/intro/intro2.rs!

🎉 🎉  The code is compiling! 🎉 🎉

Output:
====================
Hello!

====================

You can keep working on this exercise,
or jump into the next one by removing the `I AM NOT DONE` comment:

 6 |  // hint.
 7 |
 8 |  // I AM NOT DONE
 9 |
Welcome to watch mode! You can type 'help' to get an overview of the commands you can use here.
```
]
#block_help[
  代码编译通过之后，记得移除 `// I AM NOT DONE` 这行注释
]


#block_code_in_one_page(9pt)[
```rust
Progress: [------------------------------------------------------------] 0/110
Progress: [>-----------------------------------------------------------] 1/110 (0.0 %)
⚠️  Compiling of exercises/variables/variables1.rs failed! Please try again. Here's the output:
error[E0425]: cannot find value `x` in this scope
  --> exercises/variables/variables1.rs:11:5
   |
11 |     x = 5;
   |     ^
   |
help: you might have meant to introduce a new binding
   |
11 |     let x = 5;
   |     +++

error[E0425]: cannot find value `x` in this scope
  --> exercises/variables/variables1.rs:12:36
   |
12 |     println!("x has the value {}", x);
   |                                    ^ not found in this scope

error: aborting due to 2 previous errors

For more information about this error, try `rustc --explain E0425`.
```
]

#block_code_in_one_page(9pt)[
```
...
For more information about this error, try `rustc --explain E0425`.

Welcome to watch mode! You can type 'help' to get an overview of the commands you can use here.
help
Commands available to you in watch mode:
  hint   - prints the current exercise's hint
  clear  - clears the screen
  quit   - quits watch mode
  !<cmd> - executes a command, like `!rustc --explain E0381`
  help   - displays this help message

Watch mode automatically re-evaluates the current exercise
when you edit a file's contents.
```
]

在 `rustlings watch` 命令下，遇到问题可以键盘输入 `help`，按回车，就会获得上述交互信息。它提示你可以继续输入 `hint` 或者 `!<cmd>` 来获得提示。

#block_code_in_one_page(9pt)[
```
hint
The declaration on line 8 is missing a keyword that is needed in Rust to create a new variable binding.
```
]

#pagebreak()

#block_code_in_one_page(9pt)[
```rust
!rustc --explain E0425
An unresolved name was used.

Erroneous code examples:

something_that_doesnt_exist::foo;
// error: unresolved name `something_that_doesnt_exist::foo`

// or:
trait Foo {
    fn bar() {
        Self; // error: unresolved name `Self`
    }
}

// or:
let x = unknown_variable;  // error: unresolved name `unknown_variable`

Please verify that the name wasn't misspelled and ensure that the identifier being referred to is valid for the given situation. Example: ...
```
]

#c[rustc --explain E0425] 命令解释了编译器提供的错误码的含义。

你也可在线查看这个错误码 #link("https://doc.rust-lang.org/error_codes/E0425.html")[E0425]。

#pagebreak()
#block_code_in_one_page(9.5pt)[
```
$ rustlings watch
Progress: 🎉 All exercises completed! 🎉

+----------------------------------------------------+
|          You made it to the Fe-nish line!          |
+--------------------------  ------------------------+
                          \\/
     ▒▒          ▒▒▒▒▒▒▒▒      ▒▒▒▒▒▒▒▒          ▒▒
   ▒▒▒▒  ▒▒    ▒▒        ▒▒  ▒▒        ▒▒    ▒▒  ▒▒▒▒
   ▒▒▒▒  ▒▒  ▒▒            ▒▒            ▒▒  ▒▒  ▒▒▒▒
 ░░▒▒▒▒░░▒▒  ▒▒            ▒▒            ▒▒  ▒▒░░▒▒▒▒
   ▓▓▓▓▓▓▓▓  ▓▓      ▓▓██  ▓▓  ▓▓██      ▓▓  ▓▓▓▓▓▓▓▓
     ▒▒▒▒    ▒▒      ████  ▒▒  ████      ▒▒░░  ▒▒▒▒
       ▒▒  ▒▒▒▒▒▒        ▒▒▒▒▒▒        ▒▒▒▒▒▒  ▒▒
         ▒▒▒▒▒▒▒▒▒▒▓▓▓▓▓▓▒▒▒▒▒▒▒▒▓▓▒▒▓▓▒▒▒▒▒▒▒▒
           ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒
             ▒▒▒▒▒▒▒▒▒▒██▒▒▒▒▒▒██▒▒▒▒▒▒▒▒▒▒
           ▒▒  ▒▒▒▒▒▒▒▒▒▒██████▒▒▒▒▒▒▒▒▒▒  ▒▒
         ▒▒    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▒▒
       ▒▒    ▒▒    ▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒▒    ▒▒    ▒▒
       ▒▒  ▒▒    ▒▒                  ▒▒    ▒▒  ▒▒
           ▒▒  ▒▒                      ▒▒  ▒▒

We hope you enjoyed learning about the various aspects of Rust!
```
]
]
]