# Changelog

## Unreleased (in master)

- Added proper structure support for C/C++ mode

- Base scheme support on the newer lisp mode instead of old basic mode

- Added the `**popup_menu_accept_key` option, for controlling which key accepts
the current option for a popup menu, such as the completion popup. Valid values
are 'enter' (the default) or 'tab'.

- Close completion popup when user activity warrants it (e.g. direction keys,
clicking in another location using the mouse, etc.)

- Performance and functionality improvements for the matcher, used in Howl
selection lists, enabling fast matching across much larger data sets.

- Performance improvements for recursive file selections (`project-open` and
ordinary recursive `open` command): Between 30x and 32x faster.

- Respect use_tabs option when commenting

- Ensure scrolling works correctly for Gtk+ 3.4

- Dart bundle enhancements: improved syntax highlighting

- Added support for activities - potentially longer running activities that
should run in a apparently blocking way to the user. Example: Loading files from
larger directories will now be run as a user visible and user cancellable
operation if it takes to long to complete.

- Added a new commandline flag, `--run-async`, for running a particular file in
a asynchronous Howl context.

- Added support for shared, low precision after timers

- Fixed background drawing for Wayland/Weston/CSD environments (borders outside
of the window).

- Requested that titlebar is hidden for newer versions of Gnome 3.

- Added support for navigating back and forth in a list of previously visited
locations. Two new commands, `navigate-back` and `navigate-forward` were added,
bound to `ctrl_<` and `ctrl_>` respectively.

- Improved key translation for keys when caps lock is on.

- Added two new commands, `editor-newline-above` and `editor-newline-below`,
that insert a new line above/below the current line. Bound these commands to
`ctrl_shift_return` and `ctrl_return`.

### Github issues closed since 0.5

- Issues as seen on
[Github](https://github.com/howl-editor/howl/issues?utf8=%E2%9C%93&q=closed%3A%3E%3D2017-06-30+is%3Aissue+is%3Aclosed+sort%3Acreated-asc+)

## 0.5.3 (2017-11-07)

Added a workaround for a Gtk issue with scrollbars.

## 0.5.2 (2017-10-06)

- Fixed a bug manifesting in a SIGSEGV on OpenBSD.

## 0.5.1 (2017-07-06)

- Corrected version number given by `--version` flag

- Dart lexer fixes

## 0.5 (2017-06-30)

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
[Github](https://github.com/howl-editor/howl/issues?utf8=✓&q=closed%3A2016-05-30..2017-06-05%20is%3Aissue%20is%3Aclosedsort%3Acreated-asc)

## 0.4.1 (2016-10-14)

- Make scrollbars themeable (on newer Gtk versions). Avoids the problem where a
theme with black scrollbars would make the scrollbars effectively invisible.

- Makefile fixes for FreeBSD (thanks @maxc01)

- Compatibility fixes for certain Gtk versions and window managers where the
  window would end up with a lot of extra outer padding.

## 0.4 (2016-05-30)

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

## 0.3 (2015-09-01)

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

- A slew of issues as seen on [Github](https://github.com/howl-editor/howl/issues?utf8=%E2%9C%93&q=created%3A%3E2015-05-09+created%3A%3C2015-09-02+state%3Aclosed++type%3Aissue)

- Fix highlighting of "bad braces", i.e. braches for which no match could be
found.

### API changes

- The old readline API was significantly revamped for this release, with changes
too numerous to list here. The documentation for the new
[readline](http://howl.io/doc/api/interact.html) module is a good starting point
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

## 0.2.1 (2014-05-09)

- Added a new command `editor-cycle-case` that changes the case of the current
word or selection. The new case is automatically chosen based on the current
case. The command cycles through lowercase -> uppercase -> titlecase.

- Prompt before saving a buffer if the file on disk was modified (issue #25)

### Bugs fixed

- Moonscript: Fix incorrect lexing of `nil`, `true`, and `false` when they are
prefixes of an identifier.

- Haml: Properly lex attribute lists after class and id declarations

- `editor-paste` now cuts any existing selection before pasting (issue #26)

- Cairo error introduced with patch for flickering on Gtk 3 in 0.2, that was
seen on Gtk 3.4.2 (issue #28)

- Sporadic and rare LuaJIT "bad callback" panic should be fixed.

## 0.2 (2014-04-30)

- Avoid having the readline grow and shrink as much, which is annoying since it
requires the eyes to move up and down. Now the readline will only grow during
one read() invocation, and will keep the same fixed size regardless of the
amount of items in the completion list.

- Added howl.clipboard, new module for handling multiple clipboard items. A new
command, `editor-paste..`, was added as well that allows for pasting a selected
clip from the clipboard.

- Added a new configuration variable, `line_padding`, which allows for setting
extra padding for lines (issue #14)

- Removed fuzzy matching. It was noisy, and added little value.

- Added case boundary matching (e.g. 'cc' now match against 'CreditCard' and
'camelCase').

- Improved buffer-grep and buffer-structure commands:
  * They are now about an order of magnitude faster for large files (issue #7)
  * They now provide live previews by automatically showing the currently
selected line in the buffer with the search highlighting (issue #15)

- `open` command: Completing a directory with `/` now changes directory
automatically (issue #5).

- Better structure view for Python mode (issue #12)

- Scrolling is now remembered for buffers, in addition to the position that was
previously remembered.

- Command key bindings can contain partial text, enabling bindings such as `open
/bin`, which for the example would open the readline with the open command
displaying the contents of `/bin`.

- Added a new config variable, `completion_skip_auto_within`, which allows for
specifying a list of styles for which the completion list should not
automatically pop up.

- `save-as` command now prompts before overwriting an existing file.

- References to home directory are now shortened to '~' in the file prompt.

- HAML: Filters are sub lexed where possible (e.g. JavaScript)

- Added proper CoffeeScript support

Includes extensive lexing, indentation and structure support. Also supports
literate CoffeeScript.

- Improve code block completions when the start and end delimiters are the same

E.g. `///` for CoffeeScript, or fenced code blocks for Markdown.

### VI bundle

- Fix pasting of line block yanks (i.e. <y><y>/<Y>/<d><d>)
- Fix count handling for yank
- Fix <y><y> to yank current line correctly
- Support '<' and '>' in visual mode
- New bindings: 'H', 'L', 'M'
- Pulled in upstream Scintilla patch for bug where the cursor could end up
invisible when switching from insert to command

### Bugs fixed

- Completion popup now closes upon entering a non-character (issue #9)

- Brace matching of braces before the cursor are now highlighted correctly
(issue #16)

- Buffer grep fixed for buffers with empty lines

- Byte code compilation no longers requires a $DISPLAY

- Overly long lines in the readline caused horizontal scrolling (issue #8)

- `buffer-replace` command failed to handle empty replacement strings

- Boundary matching was not working correctly in all cases

- Pasting in the readline did not update completions (issue #6)

- Lib directory not found when binary was invoked without path (issue #17)

- Readline keeps focus, avoids weird state e.g. when clicking in an editor while
in the readline (issue #23).

- Ruby: Avoid over-eager lexing of regexes

- HTML mode: Don't lex strings within HTML content

- Flickering for Gtk+-3 versions 3.9.2 or greater was alleviated. It's still
pending a fully satisfactory fix however.

### Command name changes

In order to streamline the naming of commands, the below commands have been
renamed:

* toggle-fullscreen -> window-toggle-fullscreen
* toggle-maximized -> window-toggle-maximized

* reflow-paragraph -> editor-reflow-paragraph

* search-forward -> buffer-search-forward
* repeat-search -> buffer-repeat-search
* replace -> buffer-replace
* replace-pattern -> buffer-replace-pattern
* reload-buffer -> buffer-reload
* force-mode -> buffer-mode

* mode-set -> set-for-mode
* buffer-set -> set-for-buffer

* new-view-above -> view-new-above
* new-view-below -> view-new-below
* new-view-left-of -> view-new-left-of
* new-view-right-of -> view-new-right-of

In addition, the following alias has been deprecated:

* fill-paragraph (alias for editor-reflow-paragraph)

The old command names are still present and working, but are deprecated and will
be removed in a future release.

### API changes

- howl.fs.File is now at howl.io.File

The old path is deprecated and will be removed in future releases, but still
works as of now.

## 0.1.1 (2014-03-15)

- Fix incompatibility with older Gtk versions.

## 0.1 (2014-03-15)

First public release.
