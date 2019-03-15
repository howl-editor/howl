---
title: howl.ui.ListWidget
---

# howl.ui.ListWidget

## Overview

ListWidget is a widget containing a selection list. It displays a list of
options with one option highlighted - the selected item. A ListWidget is
primarily used to display a selection list attached to the [command line]. For
example, the [interact.select](../interact.html#select) interaction uses the
ListWidget to display a selection list.

ListWidget handles keystrokes bound to the 'cursor-up', 'cursor-down',
'cursor-page-up' and 'cursor-page-down' commands to change the currently
selected item. The default keystrokes bound to these commands are the `up`,
`down` , `pgup` and `pgdn` keys respectively. This widget also provides an API
to get the currently selected item and update the items in the list.

---

_See also_:

- The [CommandLine] API
- The [spec](../../spec/ui/list_widget_spec.html) for ListWidget
- The [interact.select](../interact.html#select) interaction which displays a
selection list using ListWidget

## Constructor

### ListWidget (matcher, opts={})

Creates a new ListWidget.

- `matcher` is a function that accepts a string and returns an table. Each
element in this table represents one select-able option and can be either a
string for a single column list, or a table for a multiple column list. When
each item is a table, it contains a list of strings, one each for each column.
Instead of a string, a [StyledText](styled_text.html) object can be used.

  The `matcher` is called on widget initialization and whenever the
[update()](#update) function is called. The `search_text` argument provided in
`update()` is passed to the `matcher` and the displayed items are replaced with
the new list of items returned from the `matcher`.

- `opts` is a table of options which can contain the following fields:

  - `filler_text`: _[optional, default:'~']_ The text displayed to fill up extra
space below the list of items, when the items take less space than the height of
the widget.
  - `never_shrink`: _[optional, default:false]_ When `true`, the height of the
widget does not shrink even if the list is updated to contain fewer items that
dont fill up the visible height. By default the height of the widget adjusts to
fit the items list while staying within the constrains specified by `min_height`
and `max_height`.
  - `on_selection_change`: _[optional]_ A callback function that is invoked
whenver the currently selected item changes. The callback is called with the
newly selected item as the only argument.
  - `reverse`: _[optional, default:false]_ When `true`, displays the items in
reverse order, with the first item shown at the bottom and subsequent items
above it.

## Properties

### .columns

A table specifying a header and styles for each column. The schema of this table
is identical to the `columns` argument in the
[StyledText.for_table](styled_text.html#styledtext.for_table) function.
Read/write.

### .items

A table contining the items currently displayed. Read-only.

### .max_height

The maximum height for the widget, in pixels. The height is rounded down to the
closest multiple of the line height. The widget is never taller than this
height. If the items don't fit within the height, paging is enabled. Read/write.

### .min_height

The minimum height for the widget, in pixels. The height is rounded down to the
closest multiple of the line height. The widget is never shorter than this
height. If the items don't fill up the height, the filler text is displayed on
each line to fill the extra space. Read/write.

### .selected

The currently selected item. Read/write.

### .showing

`true` when the widget is currently showing or `false` when hidden. Read-only.


## Methods


### hide ()

Hides the widget.

### show ()

Shows the widget.

### update (search_text)

Updates the list of displayed items to the items returned by calling
`matcher(search_text)`. See `matcher` in the [constructor](#constructor) above.

[CommandLine]: command_line.html
[command line]: command_line.html
