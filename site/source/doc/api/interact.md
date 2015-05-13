---
title: howl.interact
---

# howl.interact

## Overview

The howl.interact module acts as the central registry of interactions in Howl
and lets you register new interactions as well as invoke interactions. An
interaction is a piece of functionality that is invoked as a function call and
it retrieves some information from the user. Interactions use the command line,
and optionally additional widgets, to get information from the user. For
example, consider this call to the `read_text` interaction:

```moonscript
name = howl.interact.read_text prompt: 'Enter your name:'
```

Here the `read_text` interaction displays the given prompt in the command line
and lets the user type some text. When the user presses `enter`, the command
line is closed and the `read_text` function returns the text entered by user. If
the user presses `escape`, the function returns `nil`.

Interactions are commonly used to read user input when implementing interactive
[commands](command.html). Howl includes a number of built-in interactions, such
as `select_file`, which lets the user choose a file, and `select`, which lets
the user choose an item from a list of options - see [Built-in
interactions](#built-in-interactions) below for details.

An interaction is implemented as simple table that provides the name of the
interaction, a description, and either a handler or a factory field. Simple
interactions that just customize other interactions can be implemented easily
with just a *handler* function. More complex interactions that need greater
control on the command line behavior are implemented as *factory* based
interactions. Details for both handler and factory based interactions are in
[register](#register) below.

Interactions are run by the [command line], which maintains a stack of running
interactions. While one or more interactions are running, the command line API
can be used to display prompts in the command line, read and update the command
line text, as well as attach helper widgets above the command line (for example,
a [ListWidget] may show a completion list).

---

_See also:_

- The [CommandLine](ui/command_line.html) module for details about the command
line API
- The [command](command.html) module for more information about commands in Howl

## Functions

### register (def)
Registers a new interaction. Registered interactions are available as fields on
the `interact` module itself, using the interaction name.

`def` is a table with the following fields:

- `name`: _[required]_ The name of the interaction.
- `description`: _[required]_ A short description of the interaction.
- `handler` or `factory`: _[required]_ One of `handler` or `factory` must be
specified, but not both.

The `handler` function implements the interaction and returns the result of the
interaction. Here is an example definition of a handler:

```moonscript
  handler: -> howl.interact.select items: {'red', 'blue', 'green'}
```

The above handler displays a selection list containing three items and lets the
user select one. Note that it reuses the `select` interaction. Handler functions
are *blocking* - i.e. the function does not return until the result of the
interaction is available.

The handler function may accept arguments. Any arguments passed when calling the
interaction are passed through to the handler function.

Interactions can also be implemented as *factory* based interactions. The
`factory` field is a function that returns an interaction instance table. This
table describes how various events should be handled and has the following
fields:

- `run`: _[required]_ A function that is called when the interaction is invoked.
This function is called with a `finish` callback function as the first argument,
followed by all arguments that were passed in the interaction call. The command
line is displayed and holds the cursor while the interaction is active. The
interaction must call `finish` whenever the result of the interaction is ready
and it must pass the result as the argument to `finish`. The interaction is
active until `finish` is called, so it is important to call `finish` at some
point.
- `on_update`: _[optional]_ A function that is called every time the text in the
command line is updated. The interaction instance table and the new text are
passed as two arguments to the function.

  If the [command line] API is used to update the command line text from within
the `run` or the `on_update` function then `on_update` is not called. However,
if the command line text is updated when the user types some text, or from
within a keymap function, `on_update` is called.
- `keymap`: _[optional]_ A [keymap](bindings.html) that is used while the
interaction is active. This table specifies a mapping from keystroke names to
functions. When a key matching the keystroke name is pressed, the function is
invoked and the interaction instance table is passed as the first argument.

Here is an example implementation of an interaction using a factor:

```moonscript
  factory: -> {
    run: (@finish) =>
      @command_line = howl.app.window.command_line
      @command_line.prompt = 'Text:'

    on_update: (text) =>
      log.info text

    keymap:
      enter: => self.finish @command_line.text
      escape: => self.finish!
      binding_for:
        ['view-close']: => self.finish!
  }
```

The above example displays 'Text:' as the command line prompt and lets the user
enter any text in the command line. Whenever the text is updated by the user,
the interaction shows it in an info message. When the user presses `enter`, the
interaction finishes, returning the text entered by the user. If the user
presses `escape`, the interaction finishes, returning `nil`.

Note the special key called `binding_for` in the keymap. This demonstrates how a
keystroke can be specified [indirectly](bindings.html#indirect-bindings) instead
of by hard-coding. In the above example, the "view-close" key within
"binding-for" refers to the keystroke currently bound to the "view-close"
command. This means if the user presses the keystroke that is bound to the
"view-close" command - which is `alt_w` by default - the associated function
will be invoked, closing the command line and returning `nil`. If the user has
changed the key binding for the "view-close" command, that keystroke will be
bound to the function above instead.

### unregister (name)

Unregister an interaction with the name `name`.

## Built-in interactions<a name="builtin"></a>

### read_text (opts)

Lets the user enter free form text in the command line. Returns the text entered
by the user when the user presses `enter`, or `nil` if the user presses
`escape`. `opts` is a table that contains the following fields:

- `prompt`: _[optional]_ The prompt displayed in the command line.
- `title`: _[optional]_ The title displayed in the command line title bar.

Example:

```moonscript
name = howl.interact.read_text title:'Name', prompt:'Enter name:'
log.info 'Hello '..name if name
```

### select (opts)

Displays a list of options to the user and lets the user select one by using the
`up` and `down` arrow keys and pressing `enter`. Also lets the user narrow down
the options by typing something in the command line - the options list is then
filtered to show only those items that match the entered text.

Allows customization such as multiple columns, column headers, styling, user
provided selection etc. These are described below.

If the user presses `enter`, returns a table containing two fields - `selection`
and `text`, where:

- `selection` is the item selected by the user (or `nil` if `allow_new_value`
was specified and the user specified option was selected - see `allow_new_value`
below).
- `text` is the command line text at the time `enter` was pressed.

If the user presses `escape`, `nil` is returned.

`opts` is a table that specifies:

- `items` or `matcher`: _[required]_ One of `items` or `matcher` must be
specified, but not both.

  - `items` is a table containing a list of *items*, where each item represents
one select-able option and can be either a string for a single column list, or a
table for a multiple column list. When each item is a table, it contains a list
of strings, one each for each column. Instead of a string, a
[StyledText](ui/styled_text.html) object can be used as well.

  - `matcher` is a function that accepts a string and returns a table of items
similar to `items`. When called with the empty string, `matcher` should return a
list of all options. As the user types text into the command line, the `matcher`
function is called repeatedly and passed the typed text - it should return a
filtered list of items matching the given text.
- `prompt`: _[optional]_ The prompt displayed in the command line.
- `title`: _[optional]_ The title displayed in the command line title bar.
- `columns`: _[optional]_ A table containing the header text and style for each
column. Identical to the `columns` argument in the
[StyledText.for_table](ui/styled_text.html#styledtext.for_table) function.
- `keymap`: _[optional]_ An additional keymap to used for this interaction.
- `on_selection_change`: _[optional]_ A function callback that is called
whenever the user changes the currently selected item (usually by using the
arrow keys). The callback function is called with the three arguments
`(selection, text, items)`, where:
  - `selection` is the newly selected item
  - `text` is the current text in the command line
  - `items` is the current (possibly filtered) list of items
- `selection`: _[optional]_ The item that is initially selected by default. This
must be an item in the `items` list.
- `hide_until_tab`: _[optional, default: false]_ When set to `true`, the list of
items is initially hidden and only displayed when the user presses `tab`.
- `allow_new_value`: _[optional, default: false]_ When set to `true`, allows the
user to choose an option that is user specified and not available in the list of
available items. The user does this by typing some text that does not exactly
match any available option. This causes an additional option containing the
user's text to be automatically added to the list of options. The user can then
select this new option (identifiable because it shows 'New' next to it) and
press `enter`.
- `reverse`: _[optional, default: false]_ When set to `true`, the list is displayed reversed,
i.e. the first item is displayed at the bottom and subsequent items above it.

Examples:

The following example displays a list of three items with a column header. It
also lets the user specify a color that is not in the given list.

```moonscript
color = howl.interact.select
  items: {'red', 'blue', 'green'}
  columns: {{header: 'Color'}}
  allow_new_value: true
if color
  if color.selection
    log.info 'You selected:'..color.selection
  else
    log.info 'You selected a new color:'..color.text
```

The following example displays a two column list. It also shows how string
fields can be used in the items table. Unlike numerically indexed fields, string
fields are not displayed, but they can be used to associate additional data with
each item.

```moonscript
action = howl.interact.select
  items: {
    {'Run', 'Run this file', cmd: 'run'},
    {'Compile', 'Compile this file', cmd: 'compile'},
  }
if action
  if action.selection.cmd == 'run'
    log.info 'running...'
  else
    log.info 'compiling...'
```

### select_buffer (opts)

Lets the user select a buffer from a list of all buffers. `opts` is a table
containing:

- `prompt`: _[optional]_ The prompt displayed in the command line. Default is no prompt.
- `title`: _[optional]_ The title displayed in the command line title bar. Default is 'Buffers'.

Returns the [Buffer](buffer.html) selected by the user, or `nil` if the user
presses `escape`.

### select_directory (opts)

Lets the user select a directory. Displays sub directories in a completion list
and allows the user to navigate the file system using either the completion list
or typing a path in the command line.

`opts` is a table containing:

- `title`: _[optional]_ The title displayed in the command line title bar. Default is 'Directory'.
- `allow_new`: _[optional, default: false]_ When `true`, allows the user to
choose a nonexistent path by typing it in the command line and pressing enter.

Returns the [File] selected by the user, or `nil` if the user presses `escape`.
Note that if `allow_new` was specified, the returned file object may refer to a
nonexistent path.

### select_file (opts)

Lets the user select a file. Displays files in the completion list and allows
the user to navigate the file system using the completion list or typing a path
in the command line.

`opts` is a table containing:

- `title`: _[optional]_ The title displayed in the command line title bar.
Default is 'File'.
- `allow_new`: _[optional, default: false]_ When `true`, allows the user to
choose a nonexistent path by typing it in the command line and pressing enter.
- `directory_reader`: _[optional]_ A callback function that is used for getting
the list of files in any directory. The function should accept one argument - a
[File] object for a directory - and should return a list of [File] objects for
the contents of the given directory.

Returns the [File] selected by the user, or `nil` if the user presses `escape`.
Note that if `allow_new` was specified, the returned file object may refer to a
nonexistent path.

### select_file_in_project (opts)

Lets the user select a file from a completion list containing all files in the
current project. `opts` is a table containing:

- `title`: _[optional]_ The title displayed in the command line title bar.
Default is the project path.

Returns the [File] selected by the user, or `nil` if the user presses `escape`.

### yes_or_no (opts)

Lets the user select either 'Yes' or 'No' as an answer to a question. Returns
`true` if the user selects 'Yes', `false` if the user selects 'No' and `nil` if
the user presses `escape`. `opts` is table containing:

- `prompt`: _[optional]_ The prompt displayed in the command line. Default is no prompt.
- `title`: _[optional]_ The title displayed in the command line title bar. Default is no title.

[command line]: ui/command_line.html
[File]: io/file.html
[ListWidget]: ui/list_widget.html
