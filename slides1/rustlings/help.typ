#import "../utils.typ": *

#let content = [

  == `rustlings --help`

  #block_code_in_one_page(11pt)[
    #set block(width: 103%)
    ```bash
    $ rustlings --help
    Usage: rustlings [--nocapture] [-v] [<command>] [<args>]

    Rustlings is a collection of small exercises to get you used to writing and reading Rust code

    Options:
      --nocapture       show outputs from the test exercises
      -v, --version     show the executable version
      --help            display usage information

    Commands:
      verify            Verifies all exercises according to the recommended order
      watch             Reruns `verify` when files were edited
      run               Runs/Tests a single exercise
      reset             Resets a single exercise using "git stash -- <filename>"
      hint              Returns a hint for the given exercise
      list              Lists the exercises available in Rustlings
      lsp               Enable rust-analyzer for exercises
      cicvverify        cicvverify
    ```
  ]

]
