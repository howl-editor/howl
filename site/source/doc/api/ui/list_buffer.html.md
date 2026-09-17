---
title: howl.ui.ListBuffer
---

# howl.ui.ListBuffer

## Overview

A ListBuffer is a specialized kind of buffer used for display a [List] in a
buffer. It offers functionality for keeping track of visited/processed items, as
well as some generic support for file references.

---

_See also_:

- The [List] class
- The [ListWidget] class


## Functions

### ListBuffer(list, opts = {})

Creates a new ListBuffer for the given `list`. The passed in `list` is not
modified or changed, instead ListBuffer uses an internal copy.

`opts` is a table of options which can contain the following fields:

- `explain`: _[optional]_ A callable object used for providing highlighting
information. The object is invoked with the search text and the full text of the
list item's line. It should return a list of highlight segments. Each segment is
expected to itself be a list of two numbers: The first number should indicate
the start position of the highlight, and the second number the number of
characters to highlight.

- `max_rows`: _[optional, default: 1000]_ The maximum number of rows to show in
the buffer. A list could potentially contain hundred of thousands item, and
attempting to show them all in a buffer would typically be very slow.

- `on_submit`: _[optional]_ A callback to be invoked when an item from the list
is chosen. If present, the callback will be invoked with two arguments, the
selected item and a reference to the list buffer itself. An item that is
selected by the user will be marked visually to indicate that it's been
processed.

- `show_preview`: _[optional]_ A callback to be invoked when the user requests
previews to be shown. The ListBuffer class provides a default preview
implementation for list items containing file references, but for other kinds of
items a custom preview function can be provided here. The callback is expected
to provide some kind of preview to the user, but exactly how that is done is
left unspecified. The callback, if present, will be invoked with two arguments,
the item for which a preview is requested and a reference to the list buffer
itself.

- `title`: _[optional, default: '\<x\> items']_ The title for the buffer.

[ActionBuffer]: action_buffer.html
[List]: list.html
[ListWidget]: list_widget.html
