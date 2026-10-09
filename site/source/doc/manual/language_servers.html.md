---
title: Language servers
---

# Language servers

## Overview

Howl can use language servers, programs implementing the [Language Server
Protocol](https://microsoft.github.io/language-server-protocol/) (LSP), to
provide completions, inspections, documentation, definitions and references for a language. There's nothing to set up
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

Each mode lists the servers it knows about in order of preference, and the
first one that is installed is used. For example, the Python mode knows about
`zuban`, `ty`, `basedpyright`, `pyright`, `pylsp` and `jedi-language-server`.
Some other examples are `clangd` for C and C++, `gopls` for Go,
`rust-analyzer` for Rust and `lua-language-server` for Lua.

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
  implementations, for servers that support them. See [Going to
  definitions](editing.html#going-to-definitions).

- **References**: The `goto-reference` command, bound to `alt_comma` by
  default, lists the references to the symbol at the cursor and goes to the one
  you pick. When the server finds none, the project is searched for the word
  instead. See [Finding references](editing.html#finding-references).

## Choosing or disabling servers

To use a different server than the one Howl picks, set the `lsp_command`
configuration variable to the command used to start it. This takes precedence
over the servers known by the mode. To not use language servers at all, set
`lsp_enabled` to false. You'll typically want to set these for a particular
mode, for example in your `~/.howl/init.moon`:

```moonscript
-- use pyright for Python
howl.mode.configure 'python', {
  lsp_command: 'pyright-langserver --stdio'
}

-- don't use any language server for Lua
howl.mode.configure 'lua', {
  lsp_enabled: false
}
```

Both can also be set from within Howl using the `set` command, globally or for
example for a mode or a project folder only, and take effect immediately for
open files. See [Configuring Howl](configuration.html) for more on
configuration.

Howl talks to servers using the `utf-8` position encoding, and servers that
don't support it are not used.

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
installed. The log can be viewed using the `open-journal` command. A server
that fails to start properly is not started again for the rest of the session.
To see all messages sent between Howl and its servers, start Howl with the
`HOWL_LSP_TRACE` environment variable set to `1`, which prints them on the
standard output.

## For mode authors

A mode lists its known servers in the `lsp_servers` field, as commands in order
of preference:

```moonscript
{
  lsp_servers: { 'ruby-lsp', 'solargraph stdio' }
}
```

A mode that inherits from another mode inherits its servers as well, and can
opt out by specifying an empty list. Completions from the server are provided
by the `lsp` completer, which is part of the default mode's `completers`. A
mode that specifies its own `completers` needs to include `lsp` there to get
them. Modes should not set `lsp_command` in their default configuration, as
that would take precedence over a user's own setting.

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
