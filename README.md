# str.sh

> [!WARNING]
> **This project is still in development with more features to come. Some features may not work as expected, so please use it at your own risk.**

## Why?

I usually use the bash/zsh shell regularly and I made this tool because I was tired of using a billion `grep`, `wc`, `tr` and `sed` statements to perform basic string operations in the terminal.

Say you want to accomplish the following task:

- echo hello world
- convert to uppercase
- reverse that string
- check if the word "OLLEH" is in the string, and output "true" if yes, else "false"

In regular Unix-speak, you would do something like this:

```sh
echo "hello there" | tr '[:lower:]' '[:upper:]' | rev | grep -q "OLLEH" && echo "true" || echo "false" # true
```

The above command requires you to remember multiple Unix commands and their individual syntaxes. While it might look simple at first, it can get much more difficult as the text grows larger and the modifications become more complex.

With this tool, you can simplify that to this following syntax, which is much more intuitive and easier to understand:

```sh
echo "hello there" | str.upper | str.reverse | str.contains "OLLEH" # true
```

In `str.sh`, each "subcommand" _(technically a standalone command)_ is of the form `str.<subcommand>` (for example, `str.lower` converts a string to lowercase)

Most commands support reading from both multiple files and from stdin, similar to most Unix commands.

## Performance

Since str.sh uses regular Unix commands and Bash string manipulation functions under the hood, it should be pretty fast for most inputs

## Installation

Installation script coming soon

Help command screenshot (still incomplete):

![Image](image.png)
