---
title: howl.command
---

# howl.command

## Overview

The howl.command module acts as the central registry of commands in Howl, and
let's you register new commands, get information about currently available
commands and execute commands directly.

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
- `inputs`: An optional list of inputs for the command. Each input is either a
string, in which case it's looked up in [inputs], or an instance of an input
factory.

### run

### unregister

[inputs]: inputs.html
