---
title: howl.ui.List
---

# howl.ui.List

## Overview

List provides support for showing and updating a selection list in given buffer.
It displays a list of options with one option highlighted - the selected item.
The List component provides native support for optional filtering the items as
it's built around the concept of a 'matcher', which provides matching items
given a search string.

---

_See also_:

- The [ListWidget] widget
- The [spec](../../spec/ui/list_spec.html) for List

## Constructor

### List (matcher, opts={})

Creates a new List.

- `matcher` is a function that accepts a string and returns an table. Each
element in this table represents one select-able option and can be either a
string for a single column list, or a table for a multiple column list. When
each item is a table, it contains a list of items, one each for each column.
Each item can be either a string, a [StyledText](styled_text.html) object, or
something that can be converted to one of those two.

It is also possible to request that particular segments of an item are
highlighted for a particular item as it's displayed, by defining a
`.item_highlights` table on the item itself (see the [Item
highlights](#item-highlights) section at the end of this section).

  The `matcher` is called on initialization and whenever the
[update()](#update) function is called. The `search_text` argument provided in
`update()` is passed to the `matcher` and the displayed items are replaced with
the new list of items returned from the `matcher`.

- `opts` is a table of options which can contain the following fields:

  - `explain`: _[optional]_ A callable object used for providing highlighting
information. The object is invoked with the search text and the full text of the
list item's line. It should return a list of highlight segments. Each segment is
expected to itself be a list of two numbers: The first number should indicate
the start position of the highlight, and the second number the number of
characters to highlight.

  - `filler_text`: _[optional, default:'~']_ The text displayed to fill up extra
space below the list of items, when the number of displayed list items are
fewer than `.min_rows`.

  - `on_selection_change`: _[optional]_ A callback function that is invoked
whenver the currently selected item changes. The callback is called with the
newly selected item as the only argument.

  - `reverse`: _[optional, default:false]_ When `true`, displays the items in
reverse order, with the first item shown at the bottom and subsequent items
above it.

#### Item highlights

Certain segments of an item can be highlighted as they are displayed, if a
`item_highlights` table is specified for the item. Such a table should have one
sub table for each list column for which highlights should be applied,
containing one or more highlighting specifications indicating the start and end
position of the highlight, relative to the item column.

Start positions can be specified by using one of the below:

  * `start_column`: The starting column of the highlight
  * `start_index`: The starting byte-oriented column of the highlight

  End positions can be specified by using one of the below:

  * `end_column`: The ending column of the highlight
  * `end_index`: The ending byte-oriented column of the highlight
  * `count`: The end position is `count` characters away from the start position

## Properties

### columns

A table specifying a header and styles for each column. The schema of this table
is identical to the `columns` argument in the
[StyledText.for_table](styled_text.html#styledtext.for_table) function.
Read/write.

### items

A table containing the items currently displayed. Read-only.

### max_rows

The maximum number of total rows occupied by the list. This includes any header
and status rows. Should the size be small enough that not all items can be shown
the list will show a sub set of items along with a pagination indicator at the
bottom. Read/write.

### min_rows

The minimum number of total rows occupied by the list. If the number of items
aren't sufficient to fill up the number of rows, filler text is displayed on
each line to fill the extra space. Read/write.

### offset

Indicates the "page" currently showing. Always 1 unless the list is constrained
by [max_rows](#max_rows).

### page_size

The number of items currently shown. Always equal to the number of items unless
the list is constrained by [max_rows](#max_rows).

### rows_shown

The number of rows used by the list in the buffer.

### selected

The currently selected item. Read/write.

## Methods

### draw ()

"Draws" the list into the associated buffer, i.e. inserts or updates the list in
the buffer.

### insert (buffer)

Associates the list with the specified `buffer`. Any subsequent calls to
[draw](#draw) or [update](#update) will cause the list to be drawn into the
given buffer.

### next_page ()

Displays the next page of the list's item.

### on_refresh (listener)

Adds a listener to the list. The listener will be invoked every time the list is
redrawn in the associated buffer, and will be passed the list as the sole
argument.

### prev_page ()

Displays the previous page of the list's item.

### select_next ()

Selects the next item in the list. Causes the list to scroll if neccessary.

### select_prev ()

Selects the previous item in the list. Causes the list to scroll if neccessary.

### update (search_text, preserve_position = false)

Updates the list of displayed items to the items returned by calling
`matcher(search_text)`. See `matcher` in the [constructor](#constructor) above.

If `preserve_position` is true, the current position in the list is maintained
if possible.

[ListWidget]: list_widget.html
