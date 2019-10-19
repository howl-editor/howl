---
title: howl.interact
---

# howl.interact

## Overview

The howl.interact module acts as the central registry of interactions in Howl
and lets you register new interactions as well as invoke interactions.

An interaction is a piece of functionality that is invoked as a function call
and executes a user interaction such as asking the user for some text input or
displaying a list of choices and letting the user pick one. Interactions use the
command line, and optionally additional widgets, to get information from the
user. For example, consider this call to the `read_text` interaction:

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
interaction, a description, and a handler function. Handler functions are
*blocking* - i.e. the function does not return until the result of the
interaction is available.

Here is an example interaction definition:

```moonscript
howl.interact.register
  name: 'choose-color'
  description: 'Choose a primary color'
  handler: -> howl.interact.select items: {'red', 'blue', 'green'}
```

The above handler displays a selection list containing three items and lets the
user select one. Note that it invokes another interaction: `interact.select`.
Many [built-in interactions](#builtin) are provided in Howl and can be reused as
shown above to create new interactions.

Instead of calling another interaction, the handler function can also use the
 `howl.app.window.command_panel` object directly. This object provides a
[CommandPanel] API which is used to display the command line at the bottom of
the window, set prompts, set the title, read user entered text, show other
widgets such as a selection menu and so on. It is lower level than reusing a
built-in interaction, but provides more control. See the [CommandPanel] details
for more information.

When creating new interactions, the recommendation is to reuse [existing
interactions](#builtin) as much as possible rather than use the `CommandPanel`
directly. For cases where any existing interaction doesn't suffice, the
`CommandPanel` (or any other UI mechanism) can be used.

---

_See also:_

- The [CommandPanel] API for details about the command
panel and command line API
- The [command](command.html) module for more information about commands in Howl

## Functions

### register (def)
Registers a new interaction. Registered interactions are available as fields on
the `interact` module itself, using the interaction name.

`def` is a table with the following fields:

- `name`: _[required]_ The name of the interaction.
- `description`: _[required]_ A short description of the interaction.
- `handler`: _[required]_ implements the interaction and returns the result of the
interaction. See above for some example handlers.

The handler function may accept arguments. Any arguments passed when calling the
interaction are passed through to the handler function.

### unregister (name)

Unregister an interaction with the name `name`.

## Built-in interactions <a name="builtin"></a>

Howl provides a number of predefined interactions out of the box. These are
described in the following sections. All interactions are invoked with a single
`opts` argument which is a table containing fields specific to the interaction.
The optional `help` field is common to all interactions and contains a
[HelpContext].

## User text input

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

## Simple choice selection

### select (opts)

Displays a list of options to the user and lets the user select one by using the
`up` and `down` arrow keys and pressing `enter`. Also lets the user narrow down
the options by typing something in the command line - the options list is then
filtered to show only those items that match the entered text.

Allows customization such as multiple columns, column headers, styling, user
provided selection etc. These are described below.

If the user presses `enter`, returns the selected item. If the user presses
`escape`, `nil` is returned.

`opts` is a table that specifies:

- `items`: a table containing a list of *items*, where each item represents
one select-able option and can be either a string for a single column list, or a
table for a multiple column list. When each item is a table, it contains a list
of strings, one each for each column. Instead of a string, a
[StyledText](ui/styled_text.html) object can be used as well.
- `prompt`: _[optional]_ The prompt displayed in the command line.
- `title`: _[optional]_ The title displayed in the command line title bar.
- `columns`: _[optional]_ A table containing the header text and style for each
column. Identical to the `columns` argument in the
[StyledText.for_table](ui/styled_text.html#styledtext.for_table) function.
- `keymap`: _[optional]_ An additional keymap to used for this interaction.
- `on_change`: _[optional]_ A function callback that is called whenever the user
changes the currently selected item or updates the text in the command line. The
callback function is called with the three arguments `(selection, text, items)`,
where:
  - `selection` is the newly selected item
  - `text` is the current text in the command line
  - `items` is the current (possibly filtered) list of items
- `selection`: _[optional]_ The item that is initially selected by default. This
must be an item in the `items` list.
- `reverse`: _[optional, default: false]_ When set to `true`, the list is displayed reversed,
i.e. the first item is displayed at the bottom and subsequent items above it.

Examples:

The following example displays a list of three items with a column header.

```moonscript
color = howl.interact.select
  items: {'red', 'blue', 'green'}
  columns: {{header: 'Color'}}
if color
  log.info 'You selected:'..color
```

The following example displays a two column list. It also shows how string
fields can be used in the items table (`cmd: 'run'` below). Unlike numerically
indexed fields, string fields are not displayed, but they can be used to
associate additional data with each item.

```moonscript
selection = howl.interact.select
  items: {
    {'Run', 'Run this file', cmd: 'run'},
    {'Compile', 'Compile this file', cmd: 'compile'},
  }
if selection
  if selection.cmd == 'run'
    log.info 'running...'
  else
    log.info 'compiling...'
```

More advanced selection options including hierarchical menus are provided by
the `explore` interaction described below.

### select_buffer (opts)

Lets the user select a buffer from a list of all buffers. `opts` is a table
containing:

- `prompt`: _[optional]_ The prompt displayed in the command line. Default is no prompt.
- `title`: _[optional]_ The title displayed in the command line title bar. Default is 'Buffers'.

Returns the [Buffer](buffer.html) selected by the user, or `nil` if the user
presses `escape`.


### select_location(opts)

Very similar to [select](#select), but lets the user select a location from a
list of location. In addition, it displays a preview of the currently selected
option in the editor. Each item in `items` (or as returned by `matcher`) can
have the following fields:

- `file` or `buffer`: One of `file` or `buffer` must be provided. This specifies
which file or buffer is previewed in the editor when this item is selected:
  - `file`: A [File] object.
  - `buffer`: A [Buffer] object.
- `line_nr`: _[optional]_ The line number in `file` or `buffer`
- `highlights`: _[optional]_ A table of highlights to apply to the previewed
buffer line if possible. Requires that `line_nr` is given. Each highlight
specifies a span to highlight. The highlight's span can be specified in several
different fashions. It will be resolved using
[Buffer.resolve_span(..)](buffer.html#resolve_span), so please have a look at
`resolve_span`'s documentation to see the available options.

### yes_or_no (opts)

Lets the user select either 'Yes' or 'No' as an answer to a question. Returns
`true` if the user selects 'Yes', `false` if the user selects 'No' and `nil` if
the user presses `escape`. `opts` is table containing:

- `prompt`: _[optional]_ The prompt displayed in the command line. Default is no prompt.
- `title`: _[optional]_ The title displayed in the command line title bar. Default is no title.

## File and directory selection

### select_file (opts)

Lets the user select a file. Displays files in the completion list and allows
the user to navigate the file system using the completion list or typing a path
in the command line.

`opts` is a table containing:

- `title`: _[optional]_ The title displayed in the command line title bar.
Default is 'File'.
- `allow_new`: _[optional, default: false]_ When `true`, allows the user to
choose a nonexistent path by typing it in the command line and pressing enter.
- `show_subtree`: _[optional, default: false]_ When `true` the file browser
shows all files in the directory tree (including files in all subdirectories).

Returns the [File] selected by the user, or `nil` if the user presses `escape`.
Note that if `allow_new` was specified, the returned file object may refer to a
nonexistent path.

### select_file_in_project (opts)

Lets the user select a file from a completion list containing all files in the
current project. `opts` is a table containing:

- `title`: _[optional]_ The title displayed in the command line title bar.
Default is the project path.

Returns the [File] selected by the user, or `nil` if the user presses `escape`.

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

## Rich multilevel exploration

### explore (opts)<a name="explore"></a>

Allows the user to navigate a multilevel tree of items. A flat list of items at
a single level are displayed at a time and the user can go up or down the tree.
This is an advanced interaction with many options. The basic idea behind using
this interaction is that you specify items organized in a tree structure and the
interaction provides a powerful UI that allows the user to navigate the tree.

Here is an example that shows a flat list of items.

```moonscript
root = {
  display_items: -> {'road', 'air', 'sea'}
}
howl.interact.explore
  path: {root}
  prompt: 'Choose travel:'
```

The `root` object above is a single node that contains three child nodes. The
root object implements what is called the *explorer API* and it called an
*explorer object*. The `display_items` function returns the list of items under
this object. In this case, a list of strings is returned, which indicates that
these items do not have more sub-items under them.

The `path` specifies the object to start exploring at. Since we want to start at
the root, we specify `{root}`. When the above interaction is executed, the three
items under root are displayed to the user. The user can select one of those
three objects by using the `up` and `down` keys or even by typing text to filter
the list. When the user presses `enter`, the interaction is completed and
selected item is returned.

To add a nested level of items, `display_items` may return explorer objects
instead of strings:

```moonscript
root = {
  display_items: -> {
    {
      display_items: -> {'car', 'bus', 'train'}
      display_row: -> {'road'}
    }
    {
      display_items: -> {'helicopter', 'airplane'}
      display_row: -> {'air'}
    }
    {
      display_items: -> {'submarine', 'ship'}
      display_row: -> {'sea'}
    }
  }
}
howl.interact.explore
  path: {root}
  prompt: 'Choose travel:'
```

Above, each item under the root is itself an explorer object. Note that the
displayed text is now provided by the `display_row` method of each explorer.
When this interaction is run, the top level list containing `road`, `air` and
`sea` is displayed. When the user presses `enter`, the nested list of items for
the selected item is displayed. The user can then press `backspace` they are
returned to the top level choice again. This allows a simple selection for a
nested list of any depth.

#### Focussed and Selected objects

While this interaction is active, there is one explorer object that is
considered to be *in focus*. The child objects of this *focussed object* are
displayed above the command line. The arrow keys allow *selecting* one of the
child objects - that is considered the *selected* object. When you press
`enter`, the selected object becomes the new focussed object. (assuming it is an
explorer and not a string) and then its children are displayed.

#### Explorer API

Various customizations for explorers are possible. These are specified as the
following optional fields on the explorer object:

* `display_path` (function): Returns a string that gets displayed in the
prompt whenever this object is in focus.

* `display_title` (function): Returns a string that gets displayed as the command line title
whenever this is in focus.

* `display_columns` (function): Similar to the `columns` in `interact.select`
above. Provides column header and styling whenever this object is in focus. Note
that this applies to the result of `display_items` and not `display_row` on this
object.

* `display_row` (function): Returns a table containg strings to be displayed in
the selectable list. The strings represent multiple columns of a single row.
Note that this function is called when this object's parent object is in focus.

* `parse` (function): Called on every change to the text as the user is typing.
This can trigger auto-selection of a child object when the text matches some
pattern. For instance, in the directory explorer if you type 'subdir/', the
subdir explorer (if it exists) is immediately selected - you don't have to type
`enter`. This function can return one of the following:

  * `nil`: No effect.

  * `{jump_to: target}`: Here `target` must be a child of the focussed object.
  It will be immediately focussed.

  * `{jump_to_absolute: path}`: Here `path` is a table `{root, node1, node2}`
  which specifies the new object that should be focussed somewhere completely
  different in the tree.

* `preview` (function): Returns a table describing what should be previewed


## Search and replace

### buffer_search

Presents the user with an interactive search for a buffer and returns the
selected text. Optionally can also be used for search and *replace*.

Here is an example that shows how to invoke this interaction for simple search
the current buffer:

```moonscript
buf = howl.app.editor.buffer
howl.interact.buffer_search
  buffer: buf
  find: (line, query, start) -> line.text\find query, start
  replace: (_, _, _, replacement) -> replacement
```

When run, the interaction displays a preview of all lines in `buffer`. As the
user types, the `find` function is invoked to find lines that match the user's
search query. The list of matching lines is displayed and the user can use the
`up` and `down` keys to select a match. When the user presses `enter`, the
`buffer_search` function returns the selected match.

In this example, `find` uses the `string.find` method to do search within the
line. The `find` function is called with three arguments - `find(line, query,
start)` - defined as below:

* `line`: A [Line] object to find within.
* `query`: The search text entered by the user.
* `start`: An index within the line to start the search from.

The find function must either return `nil` for no match, or return two values
`match_start`, `match_end` containing the starting end ending position of the
match found in the line. It can optionally return a third value `match_info`
(only used for replacements described later).

When the user selects a match and the `buffer_search` is done, it returns a
table with the following fields:

* `chunk`: A [Chunk] in the buffer containing the selected match.
* `input_text`: The text typed by the user.

To invoke this interaction, Only `buffer` and `find` fields are essential, but a
large number of additional fields can be used for customization:

* `prompt`: The prompt displayed in the command line.
* `title`: The command line title.
* `lines`: A list of lines to search within. This can be any subset of lines
  from the buffer.
* `chunk`: A [Chunk] in the buffer to search within. Only one of `lines` or
  `chunk` may be provided.
* `once_per_line`: If `true` only searches for the first match in every line.
* `parse_line(line)`: This is an optimization feature. `parse_line` must be a
  function that accepts a [Line] and returns a table. This is called only once
  for each line at the beginning of the interaction. The returned value is used
  instead of the line when calling `find()`. This makes it possible to
  preprocess each line exactly once.
* `parse_query(query)`: This function is called once before applying any query
  on all lines. The `query` is the search text typed by the user.  The result of
  this function is then passed as `query` into the `find` function.

In addition to search, this interaction can also be used for *search and
replace*. This major change in behavior is activated by providing a `replace`
field in the `buffer_search` call. This field must be a function accepting four
parameters - `replace(chunk, match_info, query, replacement)`. When doing search
and replace, the text typed by the user is of the form `/query/replacement`. The
query is used as input to the `find` function (similar to search behavior) which
returns the found matches. *For each match*, the `replace` function is invoked
with the following arguments:

* `chunk`: A chunk containing the matching text.
* `match_info`: The `match_info` returned by `find`, if any.
* `query`: The typed query text.
* `replacement`: The typed replacement text.

The `replace` function must return the replacement text for the `chunk`. The
user can use the `up` and `down` keys within the list of matches. They can press
`alt_enter` to disable the replacement for the currently selected match. When the user presses `enter` a table with the following fields is returned:

* `input_text`: The text typed by the user (e.g. "/query/replacement").
* `replacement_count`: The number of matches replaced.
* `replacement_text`: Text with the replacements applied.
* `replacement_start_pos`: The starting position in the buffer for `replacement_text`.
* replacement_end_pos: The ending position in the buffer for `replacement_text`.

It is then the callers responsibility to apply the replacement_text on the
buffer if desired.

[Buffer]: buffer.html
[CommandPanel]: ui/command_panel.html
[File]: io/file.html
[Line]: ../spec/buffer_lines_spec.html#line-objects
[Chunk]: ../spec/buffer_lines_spec.html#line-objects
[ListWidget]: ui/list_widget.html
[HelpContext]: ui/help_context.html
