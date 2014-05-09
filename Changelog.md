# Changelog

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
