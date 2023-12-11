# Docoptz

Docoptz is slightly opinionated implementation of [Docopt] written using the
[Dash] shell. Like Docopt, it allows you to specify a program's command line
syntax by simply describing it in your `--help` messsage.


## A Simple Example

Let's say we have the simple command `merpstore` for saving/loading/listing
stuff in a key-value store. Its `--help` look like this:

    Usage: merpstore [OPTION]... [list|get KEY...|set (KEY VALUE)...]
    Get, set, or (without args) list values in a merp key/value store.

    Options:
      -c,--color[=(yes|no|auto)]  Colorize the output (default: 'yes')
                                  (default without option is 'auto')
      -f,--file=NAME              File to read (default: ~/.merpstorerc)
      -h,--help                   Display this help and exit
      -V,--version                Output version information and exit

The help message contains two parts: [Usage patterns](#usage-patterns) and
[option patterns](#option-patterns).


### Usage Patterns

The usage pattern begins with the `Usage:` followed by or more (indented) lines
which starts with the command name (`merpstore`) and possible arguments. There
may be followed by an (optional) unindented line with a short command
description.

The usage pattern could also be written as:

    Usage:
        merpstore [OPTION]... [list]
        merpstore [OPTION]... get KEY...
        merpstore [OPTION]... set (KEY VALUE)...
    Get, set, or (without args) list values in a merp key/value store.

Or even:

    Usage: merpstore [OPTION]... [ list |
                                   get KEY... |
                                   set (KEY VALUE)... ]
    Get, set, or (without args) list values in a merp key/value store.


### Option Patterns

Options may be specified directly in the [usage patterns](#usage-patterns) or
separately. The option patterns begin with `Options:` and all (optionally
indented) lines from that up until the first blank line, that also starts with
`-` is taken to be an option pattern.

    Options:
      -c,--color[=(yes|no|auto)],  Colorize the output (default: 'yes')
         --colour[=(yes|no|auto)]  (default without option is 'auto')

Aliases of the same option are separated by `,` and the comma can also be used
to continue an option pattern on the next line (as above). The description is
separated from the option by two or more spaces. Use `default:` (in the
description) to specify a default value for an option argument.

When aliases are declared in an option pattern, then all aliases may be used
wherever one of them is given in a usage pattern.

    Usage: exampy --help
    Example which REQUIRES either --help or -h to be specified.

    Option:
      -h,--help  Display this help and exit


### Pattern Syntax

* Positional arguments are written as `ARGUMENT`. They may only contain digits
  (`0-9`), upper case letters (`a-z`) and dashes (`-`) and cannot start with a
  dash on number.

* Options are written as `--list` (`-l`) or `--dir=NAME` (`-dNAME`). They may
  only contain digits (`0-9`), lower case letters (`a-z`) and dashes (`-`) and
  can only start with one or two dashes.

* Subcommands are written as `command` and must (just like options) only
  contain digits (`0-9`), lower case letters (`a-z`) and dashes (`-`) and
  cannot start with a dash or number.

To specify patterns you may use:

* `[` … `]` indicates an optional grouping. E.g. `[FILE]` could be used to
  indicate an optional filename.

* `(` … `)` indicates a required grouping. Not needed when repeating a single
  argument (`FILE...`) but useful for alternatives (`(FILE|URL)`) repeating
  multiple things (`(KEY VALUE)...`).

* `|` indicates logical 'or' in a grouping. For example `(get|set)` requires
  either `get` or `set`.

* `...` indicates a repetition. You could for example use `FILE...` to indicate
  one or more files need to be specified (`[FILE]...` for zero or more files).

* `[OPTION]...` signifies zero or more options from the `Options:` section of
  your help message.

* `--` used on the command line to signify end of options meaning that any
  arguments after `--` on the command line are left as-is. (This could, for
  example, be used with the `rm` command to erase a file called `-l`, like so
  `rm -- -l`.) This behavior is always enabled in Docoptz and doesn't need to
  be included in your help message.

* `-` is used to signify that instead of reading input from a file a command
  should read standard input. You can use `-` in your help message, if you want
  to for example using `(-|FILE)` to signify that either a `FILE` or `-` may be
  specified on the command line, but since `-` is a perfectly valid value for
  `FILE` you usually don't *have* to do that.


## The Opinionated Parts

Docoptz differs from the original Docopt in the following ways:

* Optional option arguments are supported, written `--color[=WHEN]` or even
  `--color[=(yes|no|auto)]`.

* Spaces are never allowed between options and their arguments on the command
  line, so `--file abc` is *always* interpreted as option plus positional
  argument. To specify an option argument `--file=abc` (or `-fabc`) must be
  used.

* Positional arguments are written in capitals `ARGUMENT`. (The Docopt syntax
  `<argument>` is not supported).

* A default argument is placed after the keyword `default:`, there's no need
  for brackets. (Docopt requires brackets `[default: …]`.)

* Use `[OPTION]...` to specify 'any option'. This usage is familiar from the
  help pages of `grep`, `ls` etc. (The Docopt `[options]` is not supported.)

* Long options (like `--almost-all`) cannot be abbreviated on the command line,
  and are not spell checked. This is by design: Long options are intended for
  clarity (e.g. in a script or code example). If you want brevity use it a
  short alias (`-A`).

* `--` and `-` are always supported (no need to explicitly write them into the
  help message).


# Installing & Updating

Docoptz uses the Dashtap test framework which is included as a Git submodule,
so if you want to run the tests, you'll need to clone the submodules as well:

    git clone --recurse-submodules git@github.com:zrajm/docoptz.git

The same goes for when you're pulling the latest changes:

    git pull --recurse-submodules

NOTE: If a submodule is in a 'detach HEAD' state (using Git v2.34.1) when you
invoke `git pull --recurse-submodules`, the submodule will remain in detached
HEAD state, but in the main repository `git status` will report that the
submodule as unmodified. :(

The following command will output the names of all submodules that are in a
detached HEAD state:

    git submodule -q foreach 'git symbolic-ref -q HEAD || echo "$sm_path"'


# Tests

The Docoptz test suite (found in the directory `t/`) can be run using:

    prove

Docoptz comes with a test suite written using the small [Dashtap] testing
framework. It is written using the [Dash] shell and uses the [TAP] (*Test
Anything Protocol*) output format. The small Dash shell file size and fast
execution format help deliver fast testing, while the TAP protocol allow you to
use any testing tool build for TAP (e.g. the `prove` command used above that
comes with Perl).


# License

All source code in this repository is licensed under GNU General Public License
version 2.0 ([GPL-2.0]). – Except for any included external libraries and
modules which use their own licenses.

Non-source code material is licensed under Creative Commons Attribution
ShareAlike version 4.0 International ([CC-BY-SA-4.0]).

[CC-BY-SA-4.0]: LICENSE-CC-BY-SA.txt
[Dash]: http://gondor.apana.org.au/~herbert/dash "Debian Almquist SHell"
[Dashtap]: //github.com/zrajm/dashtap "Dashtap Testing Framework"
[Docopt]: //docopt.org "Docopt: Command-Line Interface Description Language"
[GPL-2.0]: LICENSE-GPL2.txt
[TAP]: //testanything.org "Test Anything Protocol"

<!--[eof]-->
