---
title: howl.command
---

# howl.command

## Overview

The howl.command module acts as the central registry of commands in Howl, and
let's you register new commands, get information about currently available
commands and execute commands directly.

A command in howl is from the user's perspective just a named piece of
functionality, such as `open` or `save`. The commands are then invoked either
explicitly by opening the command prompt (Readline) and typing the name of the
command, or indirectly via a key [binding](bindings.html). The command module
keeps track of all available commands in Howl, and also handles the command
prompt as well.

From an implementation perspective, commands are specified as command
definitions, which are simple tables, providing the name of the command, a
description, an optional [input](inputs.html) and a handler that will be invoked
for the command. While the [Readline] can be used directly to read input from
the user, the command module provides an additional layer above the Readline
that makes it easy to write a new command without having to deal with the
Readline directly. It also handles the selection of a specific command as the
user types and the instantiation of the correct command.

As an example, consider the `open` command (example slightly adapted to include
the full paths of the needed howl components):

```moonscript
howl.command.register
  name: 'open',
  description: 'Open file'
  inputs: 'file'
  handler: (file) -> howl.app\open_file file
```

The `handler` above will be invoked with the file to open once the user has
selected one. The `file` input takes care of providing the user with
completions, etc., and will convert the user input to a File instance, which is
what the `handler` will actually receive. The separation of [inputs] and command
handlers allows for keeping commands rather simple. And since the inputs can be
shared, most commands can simply re-use existing inputs. As an example, adding
another command that works on a file would also use the same `file` input.

_See also_:

- The [spec](../spec/command_spec.html) for howl.command
- The documentation for [inputs] for more information about inputs

## Functions

### alias (target, name, opts = {})

Creates an alias, `name` for an existing command, `target`. The command
specified by `target` is required to exist when calling this function. `opts` is
an optional table of options. Currently it can contain one field:

`deprecated`: If set to `true`, the alias is marked as deprecated. This will
show in the command completion.

### get (name)

Retrieves the command definition for the command with name `name`, or `nil` if
no such command is present.

### names ()

Returns a list of names for the currently available commands.

### register (def)

Registers a new command. `def` is a table of fields for the command, that can
contain the following fields:

- `name`: _[required]_ The name of the command.
- `description`: _[required]_ A short description of the command.
- `handler`: _[required]_ A callable handler that will be invoked
 to execute the command. The handler will receive arguments corresponding to the
specified inputs.
- `input`: An optional input for the command. The value can be either a string,
in which case it's looked up in [inputs], or an instance of an input factory,
which will be invoked to instantiate the input as the command is run.

### run (cmd_string = nil)

Parsed and runs `cmd_string`, if given. If `cmd_string` is not provided, then
the [Readline] is opened and the user is prompted for the command to run.
`cmd_string` can also be a partial command string, in which case the [Readline]
is invoked to allow the user to add in any required parameters.

### unregister (name)

Unregisters the command with name `name`, along with any aliases pointing to
the command.

[inputs]: inputs.html
[File]: fs/file.html
[Readline]: ui/readline.html
