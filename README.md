# micro-cli

A small declarative command-line parser for MiniScript 2, modelled on
[System.CommandLine](https://learn.microsoft.com/dotnet/standard/commandline/). You declare
the options your command takes as maps, hand the parser the shell arguments, and it hands
back the values — along with `--help` and `--version` output rendered from the same
declarations, so the two can never drift apart.

One file, `cli.ms`, with no dependencies beyond the interpreter.

## Requirements

A MiniScript 2 interpreter. The command-line builds for Windows, macOS and Linux are on the
[MiniScript 2 releases page](https://github.com/JoeStrout/miniscript2/releases); the archive
for Windows unpacks to a folder holding `miniscript.exe`.

## Setup

### As a submodule at `src/cli`

```
> git submodule add https://github.com/treytomes/micro-cli.git src/cli
```

`import` names the resulting map after the path it was given, so the import is `"cli/cli"`
and the caller aliases it back to a plain name:

```miniscript
import "cli/cli"

cli = globals["cli/cli"]
```

That path is not decorative. `import` searches the entry script's own folder and its `lib`
subfolder, so a bare `import "cli"` only finds a `cli.ms` sitting directly beside the script
— a nested one has to be named.

### As a single file beside your script

Copy `cli.ms` next to your entry script and `import "cli"` works as it reads.

## Synopsis

| Call | What it does |
| --- | --- |
| `cli.newCommand(name, version, description)` | Builds a command. `description` may be `null` |
| `cli.add(cmd, option)` | Declares one option; returns the command, so calls can chain |
| `cli.parse(cmd, shellArgs)` | Parses the arguments and returns the result map |
| `cli.helpText(cmd)` | The `--help` text, as one string |
| `cli.versionLine(cmd)` | `name + " " + version` |

`parse` returns a map: `ok` (1 or 0), `error` (a message, or `null`), `values` (one entry per
declared option, holding its default when the option was absent), and the flags `help` and
`version`. Nothing is printed and nothing is exited — how to report a problem stays the
caller's decision.

An option is a map:

| Key | Meaning | Required |
| --- | --- | --- |
| `name` | Key in `values`, and how later code reads it | yes |
| `aliases` | Spellings, e.g. `["--facts", "-f"]`; defaults to `["--<name>"]` | no |
| `type` | `"flag"`, `"string"`, `"number"` or `"list"`; defaults to `"flag"` | no |
| `description` | Help text for `--help` | yes |
| `default` | Value used when the option is absent | no |

A `flag` becomes `1` when present and `0` when not; a `list` starts as `[]` and appends on
each use; a `number` is converted with a shape check, so `--times 12abc` is rejected instead
of quietly becoming `12`.

## Usage

```miniscript
import "cli"

cmd = cli.newCommand("greet", "1.0.0", "Greets someone, politely.")
cli.add(cmd, {"name": "name", "aliases": ["--name", "-n"], "type": "string",
	"default": "world", "description": "Who to greet."})
cli.add(cmd, {"name": "times", "aliases": ["--times", "-t"], "type": "number",
	"default": 1, "description": "How many greetings to print."})
cli.add(cmd, {"name": "shout", "aliases": ["--shout"], "type": "flag",
	"description": "Upper-case the greeting."})
cli.add(cmd, {"name": "tag", "aliases": ["--tag"], "type": "list",
	"description": "Extra tags to mention."})

options = cli.parse(cmd, shellArgs)
if options.help then
	print cli.helpText(cmd)
	exit 0
end if
if options.version then
	print cli.versionLine(cmd)
	exit 0
end if
if not options.ok then
	print "error: " + options.error
	exit 1
end if
print "name:  " + options.values.name
print "times: " + options.values.times
```

Pass `shellArgs` exactly as the interpreter provides it: element 0 is the script path, and
the parser skips it.

Declaring those four options is enough to generate the help text:

```
$ miniscript.exe greet.ms --help
greet 1.0.0
Greets someone, politely.

Usage:
  greet [options]

Options:
  --name, -n <TEXT>  Who to greet. (default: world)
  --times, -t <NUM>  How many greetings to print. (default: 1)
  --shout            Upper-case the greeting.
  --tag <TEXT>...    Extra tags to mention.
  --help, -h         Show this help text and exit.
  --version, -v      Show version information and exit.
```

`--help` and `--version` belong to every command without being declared, and the columns are
sized to the longest label, so a new option cannot break the layout.

Parsing:

```
$ miniscript.exe greet.ms
name:  world
times: 1

$ miniscript.exe greet.ms --name Ada --times 2 --shout
name:  Ada
times: 2

$ miniscript.exe greet.ms --name=Ada --tag a --tag b
name:  Ada
tag:   a, b
```

Both `--name Ada` and `--name=Ada` work; a `list` option appends rather than replaces.

Mistakes come back as `ok = 0` and a message that names the option:

```
$ miniscript.exe greet.ms --bogus
error: unknown option: --bogus

$ miniscript.exe greet.ms --times nope
error: --times: not a number: nope
```

Anything unrecognized is an error rather than a silently ignored argument, which is the
property that makes a parser worth having.

## One thing the shell does to you

The MiniScript CLI splits the raw command line on whitespace and keeps the quote characters,
so `--query "household_avoids(trey, ?a)"` arrives as two shell arguments — `--query="household_avoids(trey,`
and `?a)`. The parser rejoins tokens that end mid-quote before reading them, so callers see
whole strings whatever the shell did to them.

## Tests

```
> miniscript.exe test/run.ms
32 passed, 0 failed
```

The checks cover the defaults a bare command line gets, values in both spellings
(`--depth 3` and `--depth=3`), repeatable `list` options, `--help`/`-h` and `--version`/`-v`,
and each mistake the parser rejects: a value that is not a number, a missing value, an
unknown option, a stray argument, and a value given to a flag. One case rejoins a quoted
value that the shell split into pieces, and the last four check the generated help text - the
command line, an option's placeholder and its default, and the built-in options.

In this interpreter an uncaught runtime error still exits `0`, so the `N passed, M failed`
line is the real signal, not the exit code. The runner exits non-zero on a failure it
catches.

## License

MIT — see [LICENSE](LICENSE). Copyright © 2026 Trey Tomes.
