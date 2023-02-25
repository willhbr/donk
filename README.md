# DONK

_Container build system_

## Installation

```
$ shards build --release
$ cp bin/donk ~/.local/bin
$ ln -s $PWD $HOME/.donk
```

## Usage

Define a `Donk.rb` file in your project:

```ruby
ruby_runnable(
  name: "my_ruby_project",
  main: "main.rb"
)
```

And then run it:

```shell
$ donk my_ruby_project
```
