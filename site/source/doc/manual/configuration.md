---
title: Configuring Howl
---

# Configuring Howl

## Init files

Howl looks for a startup file in the Howl _user directory_: `~/.howl`. It
searches for either `~/.howl/init.lua` or `~/.howl/init.moon`. Which one
to pick depends on your preference with regards to language - `init.moon`
for [Moonscript](http://moonscript.org) and `init.lua` for
[Lua](http://www.lua.org). Should a startup file be found, it is loaded
after Howl is initialized, which includes loading all available bundles.
Howl does not have any special configuration format for use with the
startup file, instead it's just plain Lua or Moonscript. While the startup
file would typically be mostly used for various type of configuration,
there's no restriction to what you can do in it - you have access to the entire
[Howl API](../#api-reference).

You can split up your startup code in multiple files if you like. Your local
user files will be not found by an ordinary `require`, since the user directory
is not part of the search path. However, there is an `user_load` helper available
from your startup files that works the same way. For example, given
`init.moon` and `other.moon` in the Howl user directory, you could load
'other' from init like so:

```moon
other = user_load 'other'
```

Just as with `require`, paths are given without any extension. Files are
loaded only once, with subsequent loads returning the same value. The path
passed to `user_load` can contain dots, which are translated to the directory
separator before loading the file.

It is not allowed for the startup files to implicitly clobber the global
environment, and Howl will raise an error upon startup if this is detected.
Consider for instance this incorrect Lua startup file:

```lua
-- Oops, forgot the local keyword here
my_internal_var = 2
```

This would cause Howl to abort with an error upon startup. Should you for any
reason want to set a global variable, you can do so by being explicit:

```lua
_G.my_explicit_global = 2
```

(*Note*: the `user_load` helper is only available when loading startup files.)


## Configuration variables

### Overview

Things that are meant to be configurable in Howl are exposed as "configuration
variables". Configuration variables can be set either interactively from within
Howl, using the `set` command, or programmatically from code. To get an overview
of currently available variables, type `set` and press `space` at the readline to
view a list.

Configuration variables can be specified at three different levels in Howl,
in ascending order of priority:

- *Globally*

The value set for the variable is used unless overridden by a mode or buffer
specific setting (the `set` command always sets variables globally).

- *Per mode*

The value is set for a particular mode (e.g. "Lua" or "Ruby"), and is applied
whenever a buffer with that particular mode is active. The value is used unless
overridden by a buffer specific setting, and overrides any global setting.

- *Per buffer*

The value is set for a particular buffer, and is applied whenever that buffer
is active. The value overrides any mode specific or global setting.

As an example of how this could be used a real life scenario, consider the
case of indentation: You might generally prefer your source code to be indented
with two spaces. However, some languages might have generally accepted style
guidelines where four spaces is considered the norm. Even so, certain projects
written in such a language might have adopted the inexplicable custom of using
three spaces for indentation.

In such a scenario, you could set the `indent` variable to 2 globally, override
it with 4 for a given mode, and override with 3 for any buffer with an associated
file in a certain directory.

### Programmatic access

As described above, variables can be set on three different levels. No matter
the on what level they're set, they're always set (and accessed) using
`config` objects. For global accesses, you can use the main config object in
the howl namespace. For mode variables you access variables using the config
object on a particular mode instance, and similarily for buffer variables
you use the config object for a particular buffer.

The following code snipped illustrates the various ways of setting variables
on different levels:

```lua
howl.config.my_var = 'foo'
howl.mode.by_name('ruby').config.my_var = 'foo'
howl.app:new_buffer().config.my_var = 'foo'
```

### Setting variables upon startup

Let's have a look at configuring the `indent` variable as discussed in the
[overview](#overview), using the below example Moonscript init file (init.moon):

```moon
import config, mode, signal from howl
import File from howl.fs

-- Set indent globally to two spaces
config.indent = 2

-- Use four spaces for C files
mode.configure 'c', {
  indent: 4
}

-- Hook up a signal handler to set it to three for this weird project
that_project_root = File '/home/nino/code/that_project'

signal.connect 'file-opened', (args) ->
  if args.file\is_below that_project_root
    args.buffer.config.indent = 3
```

A few notes on the above example:

- There's no need to `require` any class/module/etc. that comes with Howl.
  They're all available upon access. You can still require them
  explicitly if you want to however.

- We use [mode.configure](../api/mode.html#configure) for specifying the mode
  variable rather than setting it using the config object of an existing mode
  instance. This is because we don't want to load the mode unnecessarily just
  to set a variable. Using configure() instead means that it will set once the
  mode is loaded (or straight away should the mode already be loaded).

- We use [signal.connect](../api/signal.html#connect) to add a signal handler
  for the `file-opened` signal, and set the indent for a certain buffer with
  an associated file under a given directory.

## Key bindings

Key bindings map keyboard presses to different actions within Howl. The
nitty-gritty details on how this is handled is outlined in the documentation
for the [bindings module](../api/bindings.html), and won't be repeated here.
Rather, the below Lua example illustrates how to add different kind of binding
customizations from within your init file (init.lua).

```lua
howl.bindings.push {
  -- editor specific bindings
  editor = {
    -- bind ctrl_k to a named command
    ctrl_k = 'editor-cut-to-end-of-line',

    -- bind ctrl_shift_x to a closure
    ctrl_shift_x = function(editor)
      -- replace the active chunk with a reversed bracked enclosed version
      editor.active_chunk.text = "<" .. editor.active_chunk.text.ureverse .. ">"
    end
  },

  -- Bind the Emacs find-file binding (C-x C-f) to the open command
  ctrl_x = {
    ctrl_f = 'open'
  }
}
```

## Running commands

You've seen how to invoke commands from a key binding (simply specify the
command name as a string), but sometimes you'll want to invoke commands
programmatically from within your startup file. As an example, to enter
VI mode automatically upon startup:

```moon
howl.command.vi_on!
```

Consult the documentation for the [command module](../api/command.html) for more
information.
