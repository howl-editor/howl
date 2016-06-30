---
title: howl.ui.Editor
---

# howl.ui.Editor

Editors are the primary way of manipulating [Buffer]s. They're graphical editing
components which display the contents of a buffer visually and lets the user
manipulate them. An editor always contains a buffer, and is typically always
shown to the user.

_See also_:

- The [spec](../../spec/ui/editor_spec.html) for Editor

## Properties

### active_chunk

Contains a [Chunk] representing the currently active text block. If no selection
is present, the chunk contains the entire buffer. With a selection present, the
chunk spans the current [selection][Selection].

### active_lines

Contains a list of the currently active lines. If no selection is present, this
will contain one element, the [current line][.current_line]. With a selection
present, this holds all [Line]s included in the current [selection][Selection].

### buffer

Contains the current [Buffer].

Assigning another buffer to this property would cause that buffer to be
displayed in the editor, and would cause the `before-buffer-switch` and
`after-buffer-switch` signals to be emitted.

### cursor

A [Cursor] instance for the particular editor. Can be used to access and
manipulate the cursor.

### cursor_line_highlighted

A boolean controlling whether the line containing the cursor is highlighted.

Note that this is typically controlled via the `cursor_line_highlighted`
configuration variable instead of being set explicitly for an editor instance.

### current_context

Contains the currently active [context][Context], i.e. the context for the
current cursor position. Read-only.

### current_line

Contains the currently active [line][Line], i.e. the line that the cursor is
currently positioned on. Read-only.

### has_focus

True if the editor is currently focused, and false otherwise.

### horizontal_scrollbar

A boolean controlling whether the editor shows a horizontal scrollbar or not.

Note that this is typically controlled via the `horizontal_scrollbar`
configuration variable instead of being set explicitly for an editor instance.

### indentation_guides

Controls how indentation guides are shown for the particular editor. Valid
values are (strings):

- `none`: No indentation guides are shown
- `real`: Indentation guides are shown inside real indentation white space
- `on`: Indentation guides are shown

Note that this is typically controlled via the `indentation_guides`
configuration variable instead of being set explicitly for an editor instance.

### indicator

A table of "indicators" for the current editor. An error is raised if you try to
access an unknown indicator (see [register_indicator](#register_indicator) for
more information).

Example of modifying an existing indicator from a key handler:

```moonscript
howl.bindings.push {
  editor: {
    shift_i: (editor) ->
      editor.indicator.vi.label = 'My interesting VI info text'
  }
}

```

### line_at_bottom

Holds the line number of the line visible at the bottom of the editor window.
Assigning this scrolls the editor window so the specified line is visible as
close to the bottom as possible.

### line_at_center

Holds the line number of the line at the center of the editor window.
Assigning this scrolls the editor window so the specified line is as close
to the center as possible.

### line_at_top

Holds the line number of the line visible at the top of the editor window.
Assigning this scrolls the editor window so the specified line is visible as
close to the top as possible.

### line_numbers

A boolean controlling whether the editor shows line number to the left of the
text or not.

Note that this is typically controlled via the `line_numbers` configuration
variable instead of being set explicitly for an editor instance.

### line_wrapping

Controls how line wrapping is performed. Valid values are (strings):

- `none`: Lines are not wrapped
- `word`: Lines are wrapped on word boundaries
- `character`: Lines are wrapped on character boundaries

Note that this is typically controlled via the `line_wrapping` configuration
variable instead of being set explicitly for an editor instance.

### lines_on_screen

Holds the number of lines currently visible on the screen. Read-only.

### mode_at_cursor

Returns the buffer mode located at the cursor using [Buffer.mode_at].

### overtype

A boolean indicating whether typing inserts new characters in the [.buffer] or
overwrites them.

### searcher

A [Searcher] instance for the particular editor. Can be used to initialize and
manipulate searches for the containing editor.

### selection

A [Selection] instance for the particular editor. Can be used to access and
manipulate the selection.

### vertical_scrollbar

A boolean controlling whether the editor shows a vertical scrollbar or not.

Note that this is typically controlled via the `vertical_scrollbar`
configuration variable instead of being set explicitly for an editor instance.

## Functions

### Editor (buffer)

Constructs a new Editor instance, displaying the specified `buffer`. You would
typically not use this directly, but instead create a new editor via
[Application.new_editor](../application.html#new_editor).

### register_indicator (id, placement = 'bottom_right', factory = nil)

Registers an indicator with the specified `id`. Placement indicates where the
indicator should be place. Possible values (strings) are:

- `top_left`: Adds the the indicator to the top indicator bar, to the left.
- `top_right`: Adds the the indicator to the top indicator bar, to the right.
- `bottom_left`: Adds the the indicator to the bottom indicator bar, to the left.
- `bottom_right`: Adds the the indicator to the bottom indicator bar, to the right.

An indicator is a simple label by default, but it's possible to add an arbitrary
widget as an indicator via the `factory` parameter. If specified, `factory` must
be a callable object that when called returns a Gtk widget.

### unregister_indicator (id)

Unregisters the indicator with the specified `id`.

## Methods

### backward_to_match (str)

Moves the cursor backwards to the next reverse match of `str`, within the
current line. Does nothing if `str` could not be found.

### comment ()

Comments the current line or selection, if possible, by forwarding the request
to the current [mode].

### complete ()

Starts a completion at the current cursor position.

### copy_line ()

Copies the current line to the clipboard.

### delete_back ()

Deletes the preceeding character, if one is present. With a selection present,
deletes the selection.

### delete_forward ()

Deletes the the current character, if one is present. With a selection present,
deletes the selection.

### delete_line ()

Deletes the current line.

### delete_to_end_of_line ()

Deletes from the current cursor column to the end of the current line.

### duplicate_current ()

Duplicates the current line if no selection is present. With a selection
present, duplicates the text included in the selection.

### forward_to_match (str)

Moves the cursor forward to the next match of `str`, within the current line.
Does nothing if `str` could not be found in the remainder of the line.

### grab_focus ()

Grabs focus for the specified editor, i.e. causes the editor to be focused.

### indent ()

Indents the current line or selection, if possible, by forwarding the request to
the current
[mode].

### indent_all ()

Indents all lines in the current buffer if possible, by selecting all lines and
forwarding the request to the current
[mode].

### insert (text)

Inserts `text` at the current cursor position.

### join_lines ()

Joins the current line with the following line. Any space between the two lines
is collapsed to one space. The cursor is positioned at the end of the current
line, as it was before the join.

### new_line ()

Inserts a new line at the current cursor position.

### paste (opts = {})

Pastes the current contents of the clipboard, or a specific clipboard item, at
the current cursor position. `opts` is an optional table of options. It
currently can contain the following options:

- `where`: Specifies where the clip is pasted. By default, the clip is inserted
at the current cursor position, or in the case of a multi-line clipboard item
above the current line. If `where` is specified as "after", the behaviour
changes so that the clip is pasted one position to the right of the current
cursor position, or in the case of a multi-line clipboard item below the current
line.

- `clip`: A specific clipboard item to paste.

### redo ()

Redo:s the last undone edit operation, if any.

### remove_popup ()

Removes any [popup][Popup] currently showing for the editor.

### scroll_down ()

Scrolls the editor window down one line, if possible. I.e. causes the line below
the currently last showing line to be visible.

### scroll_up ()

Scrolls the editor window up one line, if possible. I.e. causes the line before
the currently first showing line to be visible.

### shift_left ()

If a selection is present, shift the entire selection one indent level to the
left. With no selection present, the current line is shifted one indentation
level to the left.

### shift_right ()

If a selection is present, shift the entire selection one indent level to the
right. With no selection present, the current line is shifted one indentation
level to the right.

### show_popup (popup, options = {})

Display the [popup][Popup] for the specific editor. The popup is displayed at
the current cursor position, unless otherwise specified in `options`. The can
only be one popup for a given editor at one time, invoking `show_popup` when an
existing popup is active will cause that popup to close.

`options` can contain the
following keys:

- `position`: The character position at which to show the popup.
- `persistent`: A boolean indicating whether the popup should remain shown as the user types. The default behaviour is to automatically remove the popup in response to a key press.

### smart_tab ()

Inserts a tab if no selection is present, and indents the current selection on
indentation level to the right if a selection is present.

The behaviour in the first case is dependent on several configuration
variables.

- Whether an actual tab is inserted or not is dependent on the `use_tabs` variable.
- Invoking `smart_tab` when in leading white-space causes the current line to be indented if the `tab_indents` variable is set to true.

### smart_back_tab ()

Dedents the current selection on indentation level to the left if a selection is
present.

If a selection is not present, then:

- It dedents the current line if the cursor is in leading white-space or at the start of line content.
- Moves the cursor one indentation level to the left if the cursor is in the middle of text.

### to_gobject ()

Returns the Gtk view for the Editor.

### toggle_comment ()

Comments or uncomments the current line or selection, if possible, by forwarding
the request to the current [mode].

### transform_active_lines (f)

A helper for transforming [.active_lines] within the scope of
[Buffer.as_one_undo](../buffer.html#as_one_undo) for the current buffer. Invokes
`f` with [.active_lines], with any modifications being recorded as one undo
operation.

### uncomment ()

Uncomments the current line or selection, if possible, by forwarding the request
to the current
[mode].

### undo ()

Undo:s the last edit operation, if any.

### with_position_restored (f)

Invokes `f`, and restores the position to the original line and column after `f`
has returned. Should the indentation level for the current line have changed,
attempts to automatically adjust the column for the new indentation.

[.active_lines]: #.active_lines
[.buffer]: #.buffer
[.current_line]: #.current_line
[Buffer]: ../buffer.html
[Buffer.mode_at]: ../buffer.html#mode_at
[Chunk]: ../chunk.html
[Context]: ../context.html
[Cursor]: cursor.html
[Line]: ../line.html
[mode]: ../mode.html
[Searcher]: searcher.html
[Selection]: selection.html
[Popup]: popup.html
