---
title: Howl 0.2 Released
location: Stockholm, Sweden
---

![howl-0.2](blog/0-2-released/howl-02.png)

It's been only a short while since the first 0.1 release, yet the 0.2 release of
the [Howl editor](http://howl.io) comes with a lot of improvements. It's not a
revolutionary release, in that it does not contain any major changes, but
instead it contains many smaller fixes, features and improvements. The release
is available for download [here](/getit.html). The full changelog between 0.1
and 0.2 is included at the bottom of this page for your convenience, but here
are some highlights for the 0.2 release:

READMORE

### Improved buffer-grep and buffer-structure commands

The `buffer-grep` and `buffer-structure` commands were present in 0.1 already,
but they have been significantly improved. First off, they did not work well
with larger files in 0.1 as the implementation was very naive. Thanks to
[Shalabh Chaturvedi](https://github.com/shalabhc), that's no longer the case.
Both commands are now about an order of magnitude or so faster than in 0.1.
Shalabh also added the nice touch of providing live previews for these commands,
allowing you to quickly step through matches and see the context:

![Buffer grep](/images/doc/buffer-grep.png)

### Improved Readline experience

The Readline got some love in 0.2, with lots of smaller tweaks. For one, it does
not resize as aggressively as it did in 0.1, where it would grow and shrink to
fit the current content. The problem with that was it made it hard on the eyes,
since you continually had to refocus as you filtered a list, e.g. when opening
files. Starting with 0.2, it will now only grow in height during one Readline
session. The Readline now also properly handles pasted input, which allows for
pasting old commands. Somewhat related, the possibility to bind partial commands
to keys have been improved, making it possible to bind non-complete commands
such as:

```lua
howl.bindings.push { ctrl_shift_o = 'open ~/my/often-used/dir' }
```

The above binding would open up the command prompt and allow you to start
selecting files from `~/my/often-used/dir`.

### A new clipboard module

The 0.1 release used the system clipboard. Starting with the 0.2 release, Howl
keeps its own clipboard, which can be fully controlled and accessed via the
[API](/doc/api/clipboard.html). An immediate benefit of this is that there's now
a history of previous clips, that can be referenced for pasting. The new
`editor-paste..` command (bound to `ctrl_shift_v` in the default keymap) allows you
paste any previous clip from the clipboard:

![Clipboard paste](doc/clipboard-paste.png)

The new clipboard automatically synchronizes with the system clipboard, so
copy/paste to and from other application still works as expected.

### New bundle for CoffeeScript

Howl previously had some basic support for CoffeeScript, which was limited to
incomplete syntax highlighting. 0.2 includes a new CoffeeScript bundle with
comprehensive syntax highlighting, indentation support, and structure support.
And it also includes support for literate CoffeeScript!

![CoffeeScript support](blog/0-2-released/coffeescript-support.png)

### Packaged for ArchLinux

![ArchLinux](logos/archlinux-logo.png)

Starting with 0.2, and courtesy of [Bartłomiej
Piotrowski](http://bpiotrowski.pl), Howl is now available as a package in the
[Arch User Repository](https://aur.archlinux.org/) (AUR). You can install it
using your AUR
[helper](https://wiki.archlinux.org/index.php/AUR_Helpers) of choice, or by
doing a manual install from AUR. As an example, using the `packer` helper you
can install Howl by issuing:

```shell
$ sudo packer -S howl-editor
```

### In closing..

The above are some highlights, but below you'll find the complete Changelog
detailing all changes since the 0.1 release in case you're interested.

That's all for this announcement, thanks for reading!

## Full Changelog since 0.1

### New and improved

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

- Added proper CoffeeScript support. Includes extensive lexing, indentation and
structure support. Also supports literate CoffeeScript.

- Improve code block completions when the start and end delimiters are the same.
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

- Byte code compilation no longer requires a $DISPLAY

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

- howl.fs.File is now at howl.io.File. The old path is deprecated and will be
removed in future releases, but still works as of now.
