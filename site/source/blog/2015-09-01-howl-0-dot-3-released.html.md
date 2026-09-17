---
title: Howl 0.3 Released
location: Stockholm, Sweden
---

![howl-0.3](/images/blog/0-3-released/howl-0.3.png)

The eagerly awaited 0.3 release of the [Howl editor](http://howl.io) is finally
here! Packed with new features and numerous enhancements, the 0.3 release takes
a few big strides towards 1.0. You can download the latest version
[here](/getit.html). Highlights of this release are below and the full changelog
since 0.2.1 is included at the bottom of this blog post.

It's been a while since the 0.2.1 release, but that does not mean that
development has been idling. Apart from the many things already packed in the
0.3 release, a lot of work has been put into a new, custom written editing
engine code-named 'aullar'. The 0.3 release marks the last Howl release to use
the [Scintilla](http://scintilla.org) editing engine - starting with 0.4 and
going forward the new editing engine will be used. We'll write more about the
new editing engine in upcoming [blog](/blog) entries, so stay tuned!

READMORE

### External commands

You can now run external commands from within the editor and view the output in
a buffer using two new commands - `exec` and `project-exec`. The implementation
is completely non-blocking so you can continue to edit other files while your
external command is running. See the [manual](/doc/manual/running_commands.html)
for more information and this
[earlier blog post](/blog/2014/11/13/external-commands-support.html) for a nice
demo of this feature.

Here is screenshot showing the external command prompt in
action:

![External command prompt](/images/blog/0-3-released/exec-prompt.png)

### Revamped command line API

The readline and inputs API has been completely revamped and replaced with a new
[`CommmandLine`](/doc/api/ui/command_line.html) and
[interactions](/doc/api/interact.html) APIs.

### New and improved commands

The `buffer-replace` command is now interactive and displays a preview, while
allowing selective exclusion of matches from replacement. A new command
`buffer-replace-regex` allows replacements of text that matches a given regular
expression. See the
[manual](/doc/manual/editing.html#replacement) for more information.

Here is a screenshot showing `buffer-replace` in action:

![Interactive buffer-replace](/images/blog/0-3-released/buffer-replace.png)

Both `project-open` and `buffer-switch` commands now show a preview of the
selected buffer or file.

A new `project-build` command executes a pre-configured build command from the
current project's root directory.

### New bundles

The [Python](http://python.org/), [Nim](http://nim-lang.org) and
[PHP](http://php.net) programming languages now have proper bundles supporting
lexing and language specific modes.

## Full Changelog since 0.2.1

### New and improved


- Added a new command, `project-build` that executes a pre-configured command
from the projects root directory (using the command configured in the new
`project_build_command` variable).

- New Nim bundle (lexing, structure, etc)

- New Python bundle (lexing, structure, etc). Replaces the old basic Python
mode.

- Lexer fixes: Ruby, C/C++, HTML, HAML

- Lisp and sub modes: Better indentation support

- Added previews for the `switch-buffer` and `project-open` commands.

- HTML mode: Sub lex inline styling

- Upgrade to LuaJIT 2.0.4

- Upgrade to Moonscript 0.3.1

- Replaced the readline and input system with a new command line and
interactions system resulting in new API.

- Updated the `buffer-replace` command and added a new `buffer-replace-regex`
command. Both show live previews of replacements and allow selective exclusion.

- Command history is now recorded and can be viewed by using the `up` key from
the command line. Previously run commands can be re-run by selecting them from
the history.

- New PHP bundle, featuring a new PHP mode with advanced syntax highlighting.

- The `describe-key` command now shows the commands bound to the key press.

- Added indirect bindings support to keymaps using the `binding_for` field.

- Added a new comprehensive API for launching and controlling external processes
(howl.io.Process).

- Added two new commands for launching external processes: `exec` and
`project-exec`. The former opens up a prompt for launching an external process
from the directory of the current file (if available), whereas the latter
launches an external process from the base directory of the current project.
Both opens up a new process buffer for displaying any process output (ANSI color
sequences supported).

- Substituted certain key names to avoid ambiguity, e.g. `alt_l` now gets
substituted for `altL` so that pressing left alt is distinguishable from
pressing alt + l (issue #29)

- VI:
  * Refuse to enter INSERT mode for a read-only buffer
  * Bind `?` to `buffer-search-backward`

- Added new method, `Buffer.save_as(file)`, for associating with and saving a
buffer's content to a specified file.

- Added new function, `bindings.binding_for`, for finding a binding for a
particular action.

- Added a new StyledText (howl.ui.StyledText) class in the API, used for holding
a chunk of text along with corresponding styles. ActionBuffer now supports
inserting or appending such instances. Along with this a new simple markup
parser was added (Howl Markup, howl.ui.markup.howl) that can be used to easily
create StyledText instances.

- Added a new command `buffer-search-backward` that implements an interactive
search for the text typed by the user, backwards from the cursor position. Bound
this command to `ctrl_r`.

- Enabled jumping to the next or previous match while an interactive search is
running. The bindings for `buffer-search-backward` or `buffer-search-forward`
(`ctrl_r` and `ctrl_f` by default) are used for this while either command is
active.

- Added two new commands `buffer-search-word-backward` and
`buffer-search-word-forward` that do an exact word match, using the configured
word pattern, for the current word at cursor. Bound these commands to
`ctrl_comma` and `ctrl_period`.

- Updated interactive `buffer-search-backward` and `buffer-search-forward`
commands to highlight all matches on screen in addition to the primary match.
Added a new highlight style called `search_secondary` for the non primary
matches.

- Ruby: Update lexer to properly lex bare general delimited strings, e.g.
`my_string = %{string here}`.

### Bugs fixed

- A slew of issues as seen on [Github](https://github.com/howl-editor/howl/issues?utf8=%E2%9C%93&q=created%3A%3E2015-05-09+created%3A%3C2015-08-25+state%3Aclosed++type%3Aissue)

- Fix highlighting of "bad braces", i.e. braches for which no match could be
found.

### API changes

- The old readline API was significantly revamped for this release, with changes
too numerous to list here. The documentation for the new
[readline](/doc/api/interact.html) module is a good starting point
for seeing how the new API looks.

- `Buffer.file`: Assigning a new file causes the buffer contents to always be
reloaded, regardless of the modification status. If the file does not exist, the
buffer's contents will be emptied.

- `Buffer.reload()`: `reload` now takes an additional parameter, `force`, that
allows reloading a buffer even if the buffer is currently modified.

- `Buffer.find()`, `Buffer.rfind()`: new methods that implement forward and
reverse search on the entire buffer text, or starting at `init` argument if
provided. These methods work with character offsets.

- `ustring.urfind()`, `ustring.rfind()`: new methods that implement reverse
search for a given string within the string. The `urfind` method uses character
offsets while `rfind` uses byte offsets.

### Deprecations removed

Command names deprecated in the 0.2 release have now been removed.
