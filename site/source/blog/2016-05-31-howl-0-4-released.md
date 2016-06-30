---
title: Howl 0.4 released!
location: Stockholm, Sweden
---

We are very happy to announce the release of [Howl](http://howl.io/) 0.4 - a
major milestone in the march towards 1.0! Highlights of this release are below
and the full changelog since 0.3 is included at the bottom of this blog post.

### New editing engine

This highlight of this release is the switch to
[aullar](https://github.com/howl-editor/howl/tree/master/lib/aullar) - a
custom-built editing engine for Howl. Written in Moonscript, Aullar enables new
features for Howl and is easier to customize than the Scintilla engine it
replaces. While the intention for the 0.4 release was to provide the bare
minimum of features needed for replacing Scintilla, there are a number of new
features and capabilities resulting from the switch. You can read a lot more
about the new editing engine, including some history and highlights of new
features [here](/blog/2016/05/26/introducing-aullar.html).

### New themes and theming possibilities

With the new editing engine in place, the surrounding theming support was
reworked to allow for more advanced themes. Since 0.3 Howl now has three new
built-in themes to choose from: Monokai, Steinom and Blueberry Blend. The first
of these, Monokai, is the new default theme starting with 0.4:

![Monokai theme](/images/blog/0-4-released/buffer-replace-monokai.png)

The second one, Steinom, shows off some of the new theming possibilities such as
background images and transparency:

![Steinom theme](/images/blog/0-4-released/buffer-grep-steinom.png)

### New bundles

- A new Pascal bundle was added with lexing and indentation support, etc.,
replacing the old basic Pascal bundle.

- [Go](http://golang.org) language got proper support in Howl, with support for
syntax highlighting, autocompletion (using `gocode`) and auto formatting:

![Go completions](/images/blog/0-4-released/go-completions.png)

### New and improved commands

The `open` command file browser got a few enhancements - it now shows previews
while browsing, displays icons next to filenames and also supports recursive
directory search which can be toggled by pressing `ctrl_s`. Illustrated by the
below screenshot using the new Blueberry Blend theme:

![Open enhancements](/images/blog/0-4-released/file-open-enhancements.png)

Many new commands were added, including `open-recent` to find recently closed
files, `cursor-goto-brace` to jump between brace pairs, `cursor-goto-line` to
jump to a given line number, `buffer-grep-exact` and `buffer-grep-regex` for
advanced buffer searches.

### Buffer management for the lazy

Opening new buffers aren't typically that much of a chore (and even less so in
0.4 with the new `open-recent` command), but closing them can be tedious. As a
result, it's easy to end up with some 100+ buffers open after some time even
though they're no longer of interest. Fortunately, starting with 0.4 Howl will
now automatically close old buffers for you. The manual contains [more
information](/doc/manual/files.html#closing-buffers) about how this is handled.

## Full Changelog since 0.3

### New and improved

- Added a new theme 'Blueberry Blend'

- New Pascal bundle (lexing, indentation support, etc). Replaces the old basic
Pascal mode.

- Added a new command, `cursor-goto-brace` for moving cursor to matching brace.

- Changed brace highlighting logic to match braces of same styles only.

- New [Go](http://golang.org) bundle (lexing, autocompletion and formatting).

- Added icons for buffer listings.

- Undo now resets the buffer modified flag if it reaches the original revision.

- Added a new theme, `monokai`. This will be the new default theme, starting
with the 0.4 release.

- Added a new theme, `steinom`.

- Added a new function `sys.time()` which returns the POSIX time for the system
  with microsecond resolution.

- Added a new module, 'janitor', which automatically closes old buffers and
tries to release memory back to the OS. The buffer closing is controlled by two
new configuration variables, `cleanup_min_buffers_open` and
`cleanup_close_buffers_after`.

- Added a new command, `cursor-goto-line` for going to a specified line.

- Added Timer.on_idle, for performing operations upon idle.

- Added a new property, Application.idle, for determining how long the
application has been idle.

- Added new configuration variable, `undo_limit`, for controlling the maximum
number of revisions for each buffer.

- Added the `open-recent` command, bound to `ctrl_shift_o`, to show a list of
recently closed files and let the user select one to re-open.

- Added `buffer-grep-exact` and `buffer-grep-regex` commands similar to
`buffer-grep` but using exact and regular expression matches, respectively.

- Changed how Howl loads files specified on the command line. Previously files
were loaded in different views, and now they're all loaded with one file being
shown (issue #123).

- Added recursive listing feature to file interactions. Pressing `ctrl_s` in the
`open` command now toggles between recursive and regular list of files.

- Added custom font support and Font Awesome icons for file listings.

- Added two new configuration variables for line wrapping:
  * line_wrapping_navigation
  * line_wrapping_symbol

- Upgrade LuaJIT to LuaJIT-2.1.0-beta1

- Added new bundle, 'mail-mode'.

- Added support for loading user configuration from a XDG Base Directory
compliant directory. It's not the default, but will be used if `~/.howl` is not
present and the XDG directory is.

- Added previews for the `open` command.

- Replaced the old editing engine Scintilla with a new custom written engine,
code-named `aullar`.

- The `howl-moon-eval` command was improved by automatically adjusting the
indentation levels to work as a stand-alone code chunk.

### Keymap changes

- Changed `ctrl_w` to run `buffer-close` instead of `view-close`. Added `ctrl_shift_w` for `view-close`.

### Bugs fixed

- Issues as seen on
[Github](https://github.com/howl-editor/howl/issues?utf8=%E2%9C%93&q=created%3A%3E2015-09-02+created%3A%3C%3D2016-05-30+state%3Aclosed+type%3Aissue)

### API changes

- The `on_selection_change` callback for interactions has been renamed to
`on_change` and triggers even when selection stays the same but the text
changes.

- The theming support has been updated. Custom themes for previous versions will
have to be updated for 0.4, which is easiest done by looking at the built-in
themes shipping with Howl.

