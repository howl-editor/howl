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
startup file, instead it's just plain Lua or Moonscript.

The startup file is typically used for various types of configuration, but
there's no restriction to what you can do in it - you have access to the entire
[Howl API](../#api-reference). However, some parts of the API, such as running
commands, can only be accessed after the application has fully initialized, and
needs be run within an `'app-ready'` signal handler, rather than at the top
level. For instance, this code launches the file selection command on startup:

```moon
howl.signal.connect 'app-ready', ->
  howl.command.run 'open'
```

You can split up your startup code in multiple files if you like. Your local
user files will be not found by an ordinary `require`, since the user directory
is not part of the search path. However, there is a `user_load` helper available
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
of currently available variables, type `set` and press `space` at the command
line to view a list:

![Configuration](/images/screenshots/monokai/configuration.png)

For example, to change the current theme interactively you can open up the
prompt, and type `set theme`. Pressing enter to choose the theme variable would
then present you with a list of available themes - after choosing one you can
press enter again to switch to the specified theme. See the sections below,
[Setting variables upon startup](#setting-variables-upon-startup) and
[Automatic persistence](#automatic-persistence), for information on how to
change a setting so that it persists across restarts.

### Scopes and layers

The value for each configuration variable can be set at multiple levels, called
*scopes*, and at multiple *layers* for each scope. The scope is the path for
which the configuration value applies. For instance, a configuration value set
at the *global* scope applies to all buffers. A configuration value at a
*file* scope applies to a specific file only, overriding any global value for
the same variable. A folder scope (similar to file scope, but referencing a
folder) applies a value to all files under a specific folder.

Scopes work well when the same configuration value applies to all types of files
within a scope. To use different values depending on the
[mode](getting-started.html#modes), configuration *layers* are used. A layer is
a string such as `'mode:moonscript'` and can by specified in addition to the
scope for a variable. So a value set at global scope for layer
`'mode:moonscript'` is applied to all moonscript buffers. A value set for scope
`'file/path/to/project'` and layer `'mode:python'` is applied to all python
files under the `path/to/project` folder.

### Interactive configuration

As seen above, the `set` command is used to specify values for configuration
variables. When setting the `theme`, you did not have a choice for scope because
the theme can only be specified for the `global` scope. For other variables, the
`set` command allows you to specify the scope, and optionally, the layer.

The syntax for the `set` command is:

```
set name@scope_name[layer]=value
```

While you can type out the entire command by hand, a selection list for the
scope_name and another for the value (if applicable) is displayed to make
command entry easier. Let's see a few examples of using this command to set the
`indent` configuration variable for different scopes and layers. The `indent`
variable specifies the number of characters to use for each level of
indentation.

* *Global scope*: To set the global value of indent to '3', use the command `set
indent@global=3`. Note that after you type `set indent@`, the command shows an
auto complete list containing different options for *scope* and the current
effective value at each scope.

* *For current buffer*: To set the configuration for the current buffer only to
4, use the command `set indent@buffer=4`. This applies to the currently active
buffer only, and no other buffers.

* *For current mode*: Another available option applies to the global scope and
mode layer for the current mode. This command looks something like `set
indent@global[mode:moonscript]=2` (assuming the current mode is *moonscript*).
This applies indent=2 to all buffers that are in moonscript mode.

Once you type the full command, pressing `enter` makes it effective and pressing
`escape` cancels, making no changes. You can also press `backspace` to go back
and change the selected scope, or the originally selected variable.

### Programmatic access

The Howl API can be used to update the configuration values as well. An easy way
to set (and access) variables is using `config` objects. For the global scope,
you can use the main config object in the `howl` namespace. For a specific mode,
you access variables using the config object on a particular mode instance, and
similarily for buffer variables you use the config object for a particular
buffer.

The following code snippet illustrates the various ways of setting variables on
different levels:

```lua
howl.config.my_var = 'foo'
howl.mode.by_name('ruby').config.my_var = 'foo'
howl.app:new_buffer().config.my_var = 'foo'
```

For more fine grained access to configuration variables, see the [config
API](../api/config.html).

### Setting variables upon startup

Let's have a look at configuring the `indent` variable as discussed in
[Interactive configuration](#interactive-configuration) earlier, using the below
example Moonscript init file (init.moon):

```moon
import config, mode from howl
import File from howl.io

-- Set indent globally to two spaces
config.indent = 2

-- Use four spaces for C files
mode.configure 'c', {
  indent: 4
}

-- Set it to three for this weird project
config.for_file('/home/nino/code/some_project').indent = 3
```

A few notes on the above example:

- There's no need to `require` any class/module/etc. that comes with Howl.
  They're all available upon access. You can still require them
  explicitly if you want to however.
  One exception to this is the module `howl` however. Requiring it will to an
  error preventing the editor to start.

- We use [mode.configure](../api/mode.html#configure) for specifying the mode
  variable rather than setting it using the config object of an existing mode
  instance. This is because we don't want to load the mode unnecessarily just
  to set a variable. Using configure() instead means that it will be set once
  the mode is loaded (or straight away should the mode already be loaded).

- We use [config.for_file](../api/config.html#for_file) to add access a config
  *proxy* object that sets and gets variables for the file scope.

### Automatic persistence

Howl does not automatically save any configuration variables updated via the
command line or the API. One way to save your settings is to manually update the
`init.moon` file as described in the previous section. Another way is to use the
 `save_config_on_exit` configuration variable which enables automatic
persistence of global configuration variables.

A simple way to enable automatic persistence is to add the following line to
your `init.moon`:

```moon
config.save_config_on_exit = true
```

Once `save_config_on_exit` is set to `true`, the current state of global
configuration variables is automatically saved on exit and reloaded on startup.
Note that automatic persistence applies to global variables and mode
configuration only - configuration at other scopes such as files and buffer is
not currently persisted.

Automatically persisted variables are stored in the file
`~/.howl/system/config.lua`. Any variables set via `init.moon` override the
variables automatically loaded from `config.lua`.

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
howl.signal.connect 'app-ready', ->
  howl.command.vi_on!
```

While it's possible in some cases to run commands directly in the init file, we
run this when the `app-ready` signal fires since the application needs to be
ready before activating the VI mode.

Consult the documentation for the [command module](../api/command.html) for more
information on commands.

*Next*: [Using Howl completions](completions.html)
