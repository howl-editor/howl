---
title: Language servers
---

# Language servers

## Overview

Howl can use language servers, programs implementing the [Language Server
Protocol](https://microsoft.github.io/language-server-protocol/) (LSP), to
provide completions, inspections, documentation, definitions, references,
highlights and renaming for a language. There's nothing to set up
in Howl itself: if a language server for the language you're editing is
installed, Howl starts it as needed. The language server itself needs to be
installed separately, typically via your system's package manager or the
language's own tooling.

## When servers are started

A language server is started when a file for which a server is known is shown
in an editor, but only if the file is part of a project. Files that are only
opened, such as those restored from the previous session, don't start a server
until you visit them. A project is a directory added as a
project root (as done when using `project-open`), or the root of a version
control repository containing the file. A single server is run for each
project, and is shared by all files of that project. Servers run with the
[project environment](running_commands.html#the-project-environment), so that a
Python server finds the packages of the project's virtualenv, for instance.

The bundles for the languages register the servers they know about, in order of
preference, and the first one that is installed is used. For example, the
servers known for Python are `zuban`, `ty`, `basedpyright`, `pyright`, `pylsp`
and `jedi-language-server`. Some other examples are `clangd` for C and C++,
`gopls` for Go, `rust-analyzer` for Rust and `lua-language-server` for Lua. A
server counts as installed when it's found using the `PATH` of the project
environment, so a server installed in a project's virtualenv is used for that
project.

A server that isn't used for a while is stopped automatically, and is started
again the next time you show or edit a file for it. How long is controlled by the
`lsp_server_idle_stop` configuration variable (in minutes, 30 by default), with
`0` meaning that servers are never stopped.

## What servers provide

- **Completions**: Completions from the server are shown together with the
  in-buffer completions, and completion is triggered automatically after
  characters the server specifies, such as `.`. See [Using Howl
  completions](completions.html) for more on completions.

- **Inspections**: Errors and warnings reported by the server are shown as
  inspections as you type, just like those of other inspectors, unless
  `auto_inspect` is set to 'off'. See [Inspections](editing.html#inspections)
  for more on inspections.

- **Documentation**: The `show-doc-at-cursor` command, bound to `ctrl_q` by
  default, shows the server's documentation for the symbol at the cursor. When
  the server has none, the mode's own documentation is shown if available. See
  [Documentation popup](editing.html#documentation-popup).

- **Definitions**: The `goto-definition` command, bound to `alt_period` by
  default, goes to the definition of the symbol at the cursor. When the server
  finds none, the project is searched for the word instead. The
  `goto-declaration`, `goto-type-definition` and `goto-implementation` commands
  go to the symbol's declaration, the definition of its type and its
  implementations, for servers that support them. The `goto` command shows a
  menu at the cursor of what the server can go to, references included. See
  [Going to definitions](editing.html#going-to-definitions).

- **References**: The `goto-reference` command, bound to `alt_comma` by
  default, lists the references to the symbol at the cursor and goes to the one
  you pick. When the server finds none, the project is searched for the word
  instead. See [Finding references](editing.html#finding-references).

- **Highlights**: When the cursor rests on a symbol that occurs elsewhere in
  the file, the server's list of its occurrences is highlighted, with the places
  assigning to it highlighted differently. The highlights go away when you move the
  cursor off them or edit the file. How long the cursor must rest first is set
  by `lsp_occurrences_highlight_delay`, in milliseconds (1000 by default). To
  turn this off, set `lsp_occurrences_highlighted` to false.

- **Renaming**: The `rename-symbol` command renames the symbol at the cursor
  wherever it's used, previewing the new name in each place as you type it. See
  [Renaming symbols](editing.html#renaming-symbols).

## Choosing or disabling servers

To use a different server than the one Howl picks, set the `lsp_server`
configuration variable to the name of a known server. This takes precedence
over the order of preference. For a server Howl doesn't know about, set
`lsp_server` to a server definition instead, giving its name and the command
used to start it. To not use language servers at all, set
`lsp_enabled` to false. You'll typically want to set these for a particular
mode, for example in your `~/.howl/init.moon`:

```moonscript
-- use basedpyright for Python
howl.mode.configure 'python', {
  lsp_server: 'basedpyright'
}

-- use a server Howl doesn't know about for Ruby
howl.mode.configure 'ruby', {
  lsp_server: {
    name: 'my-ruby-server'
    command: 'my-ruby-server --stdio'
  }
}

-- don't use any language server for Lua
howl.mode.configure 'lua', {
  lsp_enabled: false
}
```

Both can also be set from within Howl using the `set` command, globally or for
example for a mode or a project folder only, and take effect immediately for
open files. The `set` command can only set `lsp_server` to a name. See
[Configuring Howl](configuration.html) for more on configuration.

Howl talks to servers using the `utf-8` position encoding, and servers that
don't support it are not used.

## Server options

Many servers accept options when they're started, called initialization
options. These are the server's own, so see its documentation for what they
are. They're given as `init_options` in a server definition. A definition with
the name of a known server only needs what it changes, and takes the rest from
the known server's definition. For example, to run zuban in its mypy
compatible mode, which doesn't check functions without type annotations:

```moonscript
howl.mode.configure 'python', {
  lsp_server: {
    name: 'zuban'
    init_options: { typeCheckingMode: 'mypy' }
  }
}
```

The `init_options` given replace those of the known server's definition, if
any, rather than being merged with them. Changing a server's options takes effect
immediately for open files: a server is started with the new options, and the
one used until then is stopped unless other files still use it.

## Seeing and stopping running servers

Language servers are shown in the process count in the bottom right corner of
the editor, left of the cursor position. Clicking the count, or running the
`process-list` command, opens a list of the running processes. From there you
can stop a server by pressing `s` on its line, which shuts it down cleanly. The
server is started again the next time you show or edit a file for it, which
makes this a way of restarting a misbehaving server. See [Running external
commands](running_commands.html#listing-long-running-processes) for more on the
process list.

## Troubleshooting

Howl notes in the log when it starts a server, or if a configured server isn't
installed or known. The log can be viewed using the `open-journal` command. A server
that fails to start properly is not started again for the rest of the session.
To see all messages sent between Howl and its servers, start Howl with the
`HOWL_LSP_TRACE` environment variable set to `1`, which prints them on the
standard output.

## For bundle authors

A bundle registers the servers for its modes when it's loaded, and unregisters
them when it's unloaded. A server has a `name`, the `command` used to start it,
the `modes` it serves (a mode name, or a list of them) and optionally
`init_options`. The servers for a mode are preferred in the order they're
registered, and registering a name again replaces that server in its place:

```moonscript
lsp_servers = {
  { name: 'ruby-lsp', command: 'ruby-lsp', modes: 'ruby' },
  { name: 'solargraph', command: 'solargraph stdio', modes: 'ruby' }
}
howl.lsp.register_server s for s in *lsp_servers

unload = ->
  howl.lsp.unregister_server s.name for s in *lsp_servers
```

Users pick a server by its name, so use the name the server is known by, which
isn't always the name of its executable. A server is only used for the modes
it's registered for, and not for modes inheriting from them. Completions from
the server are provided by the `lsp` completer, which is part of the default
mode's `completers`. A mode that specifies its own `completers` needs to include
`lsp` there to get them. Modes should not set `lsp_server` in their default
configuration, as that would take precedence over a user's own setting.

A bundle can add to the project environment by registering a provider, whose
handler returns the variables to set for a project, or nil. It can run
processes, and servers wait for it before they're started. Saving one of the
listed files in the project root finds the variables again:

```moonscript
howl.Project.register_environment_provider {
  name: 'my-env'
  files: { 'my-tool.toml' }
  handler: (project, vars) -> { MY_TOOL_HOME: project.root\join('.my-tool').path }
}
```

`vars` holds the variables from the providers before it, for building on a
value such as `PATH`.

---

*Next*: [What's next?](next.html)
