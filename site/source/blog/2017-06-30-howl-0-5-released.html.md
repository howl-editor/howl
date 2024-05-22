---
title: Howl 0.5 released!
location: Stockholm, Sweden
---

We are very happy to announce the release of [Howl](http://howl.io/) 0.5!
Highlights of this release are below and the full changelog since 0.4 is
included at the bottom of this blog post.

READMORE

### Code inspection support

Code inspections integrates various types of annotations, typically from linters
and similar checkers, directly into Howl:

![Buffer inspections](/images/screenshots/monokai/buffer-inspect.png)

The 0.5 release ships with built-in inspection support for

- Lua (using [luacheck](https://github.com/mpeterv/luacheck))
- Moonscript (using [moonpick](https://github.com/nilnor/moonpick))
- Ruby (using the interpreter's built-in syntax checking)

Support for more languages will likely come in the future. It's easy to add
support for your own custom inspectors as well using the new inspect API.

### Revamped configuration system

Howl has always had a pretty flexible configuration system, allowing you to set
configuration for different layers: globally, for a specific mode or a specific
buffer. With 0.5 this is cranked up a notch, as it's now possible to set
configuration not only for the aforementioned layers, but for different type of
scopes as well. Having scopes allows you to specify configuration for a
particular file for instance, or all files below a particular directory. Or
files using a particular mode below a particular directory.. It makes for a very
powerful and flexible configuration system, and is something that future
releases is likely to build upon, e.g. to introduce project specific
configuration, etc.

You can read more about the new configuration system in the
[manual](/doc/manual/configuration.html#configuration-variables).

### New bundles

- A new [Rust](http://www.rust-lang.org) bundle was added with lexing and
indentation support.

- A new Cython bundle provides syntax and structure support for
[Cython](http://cython.org) code.

- A new Dart bundle provides syntax and structure support for
[Dart](https://www.dartlang.org) code.

![New bundles](/images/blog/0-5-released/new-bundles.png)

### New and improved commands

- Added new commands `editor-move-text-left` and `editor-move-text-right`, bound
to `alt_left` and `alt_right` by default. These move the current character or
selected text left or right by one character while preserving the selection.

- Added new commands `editor-move-lines-up` and `editor-move-lines-down`, bound
to `alt_up` and `alt_down` by default. These move the current or selected lines
up (or down) by one line while preserving the selection.

- Added new command, `editor-replace-exec`, for replacing selection or buffer
content with the result of piping it to an external command.

## Full Changelog since 0.4

### New and improved

- New Dart bundle for [Dart](https://www.dartlang.org) code.

- Make fixes to let OpenBSD build cleanly (thanks @oficial)

- Various improvements for VI mode

- Code inspection support for Lua using
[luacheck](https://github.com/mpeterv/luacheck)

- Code inspection support for Ruby using Ruby interpreter

- Code inspection support for Moonscript using
[moonpick](https://github.com/nilnor/moonpick)

- Support for a new inspections framework (i.e. linting).

- New Rust bundle provides syntax and structure support for
[Rust](http://www.rust-lang.org) code.

- Added `--version` command line flag.

- Bundles can now declare dependencies on other modules using the
`require_bundle` helper function.

- Bundles can now expose modules using `provide_module` helper function.

- LuaJIT was updated to LuaJIT-2.1.0-beta3

- Theme compatibility fixes for newer Gtk versions

- Quiet Gtk size allocation warnings in newer Gtk versions

- Added support for X11 primary selection (e.g. copy & paste using middle
button).

- New Cython bundle provides syntax and structure support for
[Cython](http://cython.org) code.

- **breaking** - Default for `line-padding` setting has been changed to `0`. If
you've relied on it: set it explicitly to its' previous value `1` in your Howl
configuration.

- **breaking** - Overhauled the configuration system to use a flexible *scope*
and *layer* structure. Replaced all 'set*' commands with a new `set` command as
part of this. See the documentation for more details.

- Added `config.save_config_on_exit` variable to automatically save global
configuration to `~/.howl/system/config.lua`.

- Added the `save-config` command that saves the current global configuration to
`~/.howl/system/config.lua`.

- Changed undo coalescing to not be as greedy (e.g. coalescing pastes and
ordinary edit revisions).

- Added `custom_draw` flair type (`highlight.CUSTOM`).

- Added command line help which is invoked by pressing `f1` while any
interactive command is running. This displays a popup containing information
about the command.

- Added new commands `editor-move-text-left` and `editor-move-text-right`, bound
to `alt_left` and `alt_right` by default. These move the current character or
selected text left or right by one character while preserving the selection.

- Added new commands `editor-move-lines-up` and `editor-move-lines-down`, bound
to `alt_up` and `alt_down` by default. These move the current or selected lines
up (or down) by one line while preserving the selection.

- Bundled all required dependencies for running specs: `./bin/howl-spec` can now
be run without any type of external dependecy.

- Upgrade Moonscript to 0.5.0

- Added new command, `editor-replace-exec`, for replacing selection or buffer
content with the result of piping it to an external command.

### Bugs fixed

- Issues as seen on
[Github](https://github.com/howl-editor/howl/issues?utf8=✓&q=closed%3A2016-05-30..2017-06-05%20is%3Aissue%20is%3Aclosed
sort%3Acreated-asc)
