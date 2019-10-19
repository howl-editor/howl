---
title: howl.command
---

# howl.command

## Overview

The howl.command module acts as the central registry of commands in Howl, and
lets you register new commands, get information about currently available
commands and execute commands directly.

A command is a named piece of functionality initiated by the user, such as the
`open` command that opens a file, or the `save` command that saves the current
buffer. The user can invoke commands either explicitly by opening the command
line and typing the name of the command, or indirectly via pressing a key
[binding](bindings.html). The command module keeps track of all available
commands in Howl and uses [interactions] to read user input as necessary.

From an implementation perspective, a command definition is a simple table that
provides the name of the command, a description, an optional `input` function
and a `handler` function. As an example, consider a possible definition of an
`open` command:

```moonscript
howl.command.register
  name: 'open',
  description: 'Open a file'
  input: howl.interact.select_file
  handler: (file) -> howl.app\open_file file
```

When the user invokes this command, the `input` function is called first. In
this case an [interaction] called `select_file` is used as the input function.
It displays the command line and a completion list, allowing the user to
navigate the file system and select a file. The `select_file` function returns a
[File] object for the selected file. The `handler` function is then called and
passed the [File] object as an argument. This invokes the `open_file` function
to open the file.

If an `input` function returns `nil`, or raises an error, the `handler` is not
called. The `input` field is optional and commands that provide it are called
*interactive* commands. If a command does not specify an `input`, the `handler`
function is called directly with no arguments.

While any function can serve as the `input`, inputs often use [interactions].
Using interactions allows easy re-use of common user interaction patterns such
as asking the user a yes/no question or getting the user to select a directory.

The `input` is passed a single argument that is a table containing the following
fields:

* `prompt`: The text prompt to be displayed. Often of the form `:command-name`
* `text`: Any text value already entered by the user. This may be non blank
  if a command is selected form the history, for instance.
* `help`: A [HelpContext](ui/help_context.md) object that contains help
  information for this command.

These fields are often passed through to an [interaction] invoked inside the
input function. The interaction typically displays the prompt and handles the
text as well has help fields.

## Invocation

Commands can be invoked via code by calling `howl.command.run` or calling the
command name directly as a field of command module, for example
`howl.command.save!`, which invokes the "save" command. Command names that
contain special characters such as hyphens and spaces can be invoked by an
*accessible* name, in which all special characters are replaced with
underscores. For example, the "buffer-reload" command can be invoked via
`howl.command.buffer_reload!`.

When called via the `run` function, e.g. `howl.command.run('open')` the input
function is invoked if present and the behavior is identical to invoking the
command from the [command line](../manual/running_commands.md). When called
directly as a function, e.g. `howl.command.open(howl.io.File('/tmp/somefile))`,
the input function is not invoked and the command must be passed a value
accepted by the handler.

Here are some examples of invoking commands in various ways:


```moonscript
howl.command.save!  -- invoke "save"

howl.command.buffer_reload!  -- invokes "buffer-reload"

-- The following invokes the "open" command, but does not prompt the user for
-- a file to open. It just opens /path/to/myfile
howl.command.open howl.io.File('/path/to/some_file')

-- The following invokes the "open" command and prompts the user for a file
-- to open under /path/to/dir
howl.command.run 'open /path/to/dir'

```

---

_See also_:

- The [spec](../spec/command_spec.html) for howl.command
- The [interact](interact.html) module for more information about interactions

## Functions

### alias (target, name, opts = {})

Creates an alias, `name` for an existing command, `target`. The command
specified by `target` is required to exist when calling this function. `opts` is
an optional table of options. Currently it can contain one field:

- `deprecated`: If set to `true`, the alias is marked as deprecated. This will
show in the command completion.

### get (name)

Retrieves the command definition for the command with name `name`, or `nil` if
no such command is present.

### names ()

Returns a list of names for the currently available commands.

### register (def)

Registers a new command. `def` is a table containing the following fields:

- `name`: _[required]_ The name of the command.
- `description`: _[required]_ A short description of the command.
- `handler`: _[required]_ A function that is invoked to execute the command. The
handler receives arguments returned by the `input` field, if provided.
- `input`: _[optional]_ A function that is invoked to read user input. If
present, this function is invoked before the handler, and all return values are
passed to the handler as arguments. This function is called with a single
argument that is a table containing three fields: `prompt`, `text` and `help`
described above.

### run (cmd_string = nil)

Parses and runs `cmd_string`, if given. If `cmd_string` is not provided, then
the [command line] is displayed and the user is prompted for the command to run.
If `cmd_string` refers to an interactive command, the `input` function is called
first, and the results of the input function are passed to the `handler`
function.

Interactive commands can be invoked with a string containing the command name
followed by a space and some additional text, which then gets handled by the
command's `input` function. For example `command.run "open path/to/folder"`
behaves the same as running `open` and then typing "path/to/folder".

Here are some examples of invoking commands using the `run` function:

```moonscript
howl.command.run "save"  -- invokes "save"

howl.command.run "buffer-reload"  -- invokes "buffer_reload"

-- The following invokes the "open" command. Since it is an interactive command,
-- this displays the command line and lets the user select a file to open.
howl.command.run "open"
```

### unregister (name)

Unregisters the command with name `name`, along with any aliases pointing to
the command.

[interaction]: interact.html
[interactions]: interact.html
[File]: io/file.html
[command line]: ui/command_line.html
