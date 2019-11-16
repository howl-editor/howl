---
title: howl.ui.Cursor
---

# howl.ui.Cursor

## Overview

A cursor is associated with a particular [Editor], and represents the
cursor/caret/point for that editor. It provides a veritable smorgasbord of
operations for manipulating the cursor, as well as properties that can be used
for obtaining information about the cursor as well as moving it. You would never
create a Cursor instance yourself; instead you access a cursor instance through
[Editor.cursor](editor.html#cursor).

The cursor is also aware of the Editor's [Selection], in particular it will
honor a persistent selection by adjusting the selection upon any cursor
movement.

_See also_:

- The [spec](../../spec/ui/cursor_spec.html) for Cursor

## Properties

### column

The column at where the cursor currently is. Setting it moves the cursor to the
specified column. This refers to the visual column, and not necessarily to the
character offset for the current line. For a line not containing tabs, these
will be the same. With tabs, however, the column can be greater than the
corresponding string offset for the line. See [column_index](#column_index) if
you need access to the string offset instead. Consider:

```moonscript
text = '\tstart'
-- with the above loaded into 'editor', and config.tab_width = 4..
editor.cursor.pos = 2
editor.cursor.column -- => 5
editor.cursor.column_index -- => 2
```

### at_end_of_line

True if the cursor is currently at the end of the line, and false otherwise.

### at_start_of_line

True if the cursor is currently at the start of the line, and false otherwise.

### blink_interval

The interval at which the cursor blinks, in milliseconds. You would typically
not set this directly on a cursor instance, since it's controlled with the
`cursor_blink_interval` configuration variable.

### column_index

The "real" column at where the cursor currently is. Setting it moves the cursor
to the specified column. This refers to the "real" column, and not necessarily
the column you visually perceive the cursor to be at. For a line not containing
tabs, these will be the same. With tabs, however, the column_index can be
smaller than what the graphical column appears to be. See [column](#column) for
more information about this.

### line

The line at where the cursor currently is. Setting it moves the cursor to the
specified line. Any out of bounds line numbers are automatically adjusted upon
assignment.

### pos

The position of the cursor relative to the documents start. Setting it moves the
cursor to the specified offset. Any out of bounds offsets are automatically
adjusted upon assignment.

### style

The "style" of the cursor. Can be either "block" or "line", for a wide block
cursor or standard thin line cursor.

## Methods

### down (extend = false)

Moves the cursor down one line. If `extend` is true, creates a new selection, or
extends the selection if already present.

###up (extend = false)

Moves the cursor up a line. If `extend` is true, creates a new selection, or
extends the selection if already present.

### left (extend = false)

Moves the cursor left one character. If `extend` is true, creates a new
selection, or extends the selection if already present.

### right (extend = false)

Moves the cursor right one character. If `extend` is true, creates a new
selection, or extends the selection if already present.

### word_left (extend = false)

Moves the cursor one word left. If `extend` is true, creates a new selection, or
extends the selection if already present.

### word_left_end (extend = false)

Moves the cursor left, to the end of the preceding word. If `extend` is true,
creates a new selection, or extends the selection if already present.

### word_part_left (extend = false)

Moves the cursor left, to the start of word part. If `extend` is true, creates a
new selection, or extends the selection if already present.

### word_right (extend = false)

Moves the cursor one word right. If `extend` is true, creates a new selection,
or extends the selection if already present.

### word_right_end (extend = false)

Moves the cursor right, to the end of the word. If `extend` is true, creates a
new selection, or extends the selection if already present.

### word_part_right (extend = false)

Moves the cursor right, to the start of the next word part. If `extend` is true,
creates a new selection, or extends the selection if already present.

### home (extend = false)

Moves the cursor to the first column of the line. If `extend` is true, creates a
new selection, or extends the selection if already present.

### home_indent (extend = false)

Moves the cursor to the first non-blank column. If `extend` is true, creates a
new selection, or extends the selection if already present.

### home_indent_display (extend = false)

Moves the cursor to the first non-blank column of the display line. If `extend`
is true, creates a new selection, or extends the selection if already present.

### home_display (extend = false)

Moves the cursor to the first column of the display line. If `extend` is true,
creates a new selection, or extends the selection if already present.

### home_auto (extend = false)

Moves the cursor the first column of the real or display line. If `extend` is
true, creates a new selection, or extends the selection if already present.

### home_indent_auto (extend = false)

Moves the cursor the first column or the first non-blank column. If `extend` is
true, creates a new selection, or extends the selection if already present.

### line_end (extend = false)

Moves the cursor to the end of line. If `extend` is true, creates a new
selection, or extends the selection if already present.

### line_end_display (extend = false)

Moves the cursor to the end of the display line. If `extend` is true, creates a
new selection, or extends the selection if already present.

### line_end_auto (extend = false)

Moves the cursor to the end of the real or display line. If `extend` is true,
creates a new selection, or extends the selection if already present.

### move_to (opts = {})

Moves the cursor according to `opts`, which can contain the following options:

- `pos`: Moves the cursor to the specified offset
- `line`: Moves the cursor to the specified line
- `column`: Moves the cursor to the specified line column on the target line
- `column_index`: Moves the cursor to the specified line offset on the target
line
- `extend`: Extend the selection (or create a new) from the current cursor
position to the new cursor position

Not all of these are combinable. apart from `extend` which can always be
specified in order to extend the selection. You can choose to specify `pos` to
move the cursor to a specific position, specify `line` to go to a specific line,
`column` or `column_index` to go to a specific column, or finally a combination
of `line` and either `column` or `column_index` to move the cursor to a certain
column on a certain line. For the difference between `column` and `column_index`
see the documentation for [column](#column) and
[column_index](#column_index), respectively.

For example:

```moonscript
cursor = editor.cursor

-- move the cursor to the tenth offset, extending the selection
cursor\move_to pos: 10, extend: true

-- move the cursor to the third line, fifth visual column
cursor\move_to line: 3, column: 5
```

### start (extend = false)

Moves the cursor to the start of the buffer. If `extend` is true, creates a new
selection, or extends the selection if already present.

### eof (extend = false)

Moves the cursor to the end of the buffer. If `extend` is true, creates a new
selection, or extends the selection if already present.

### page_up (extend = false)

Moves the cursor one page up. If `extend` is true, creates a new selection, or
extends the selection if already present.

### page_down (extend = false)

Moves the cursor one page down. If `extend` is true, creates a new selection, or
extends the selection if already present.

### para_down (extend = false)

Moves the cursor one paragraph down. If `extend` is true, creates a new
selection, or extends the selection if already present.

### para_up (extend = false)

Moves the cursor one paragraph up. If `extend` is true, creates a new selection,
or extends the selection if already present.

### goto_matching_brace ()

Moves the cursor to brace matching the current brace if any.

[Editor]: editor.html
[Selection]: selection.html
