---
title: howl.ui.BufferPopup
---

# howl.ui.BufferPopup

## Overview

A BufferPopup is a [Popup] that displays the contents of a [Buffer], typically an
[ActionBuffer] holding [StyledText]. It's shown in an editor using the
[Editor]'s `show_popup` method:

```moonscript
buf = howl.ui.ActionBuffer!
buf\append 'Hello', 'keyword'
buf\append ' from a popup'
howl.app.editor\show_popup howl.ui.BufferPopup buf
```

The popup sizes itself to fit the buffer's contents. The size is updated when the
popup is shown, when its buffer is changed, and as the buffer is modified while
the popup is showing, so the buffer can be filled before or after creating the
popup.

---

_See also_:

- The [Popup] class which BufferPopup is based upon
- The [Editor] API, for showing popups
- The [spec](../../spec/ui/buffer_popup_spec.html) for BufferPopup

## Constructor

### BufferPopup (buffer, opts = {})

Creates a new BufferPopup displaying `buffer`. `opts` can contain the following
keys:

- `scrollable`: When true, the popup handles keys for scrolling its contents
(`up`, `down`, `left`, `right`, `home`, `end`, `page_up`, `page_down`, `space`
and `backspace`) and `escape` for closing it.
- `show_lines`: The maximum number of lines to show. By default all lines are
shown, except for an empty last line.
- `show_line_numbers`: Whether to show line numbers. Defaults to false.
- `first_visible_line`, `middle_visible_line`, `last_visible_line`: A line to
show at the top, middle or bottom of the popup.

## Properties

### buffer

The displayed buffer. Assigning a new buffer displays it instead, and resizes the
popup to fit it.

### height

The height of the popup, in pixels.

### showing

Whether the popup is currently showing.

### view

The underlying view displaying the buffer.

### width

The width of the popup, in pixels.

## Methods

### close ()

Closes the popup. The popup can be shown again afterwards.

### release ()

Closes the popup and releases its resources. The popup can not be used
afterwards.

### resize ()

Resizes the popup to fit the buffer's contents. This is done automatically, so
there's normally no need to call it.

[ActionBuffer]: action_buffer.html
[Buffer]: ../buffer.html
[Editor]: editor.html
[Popup]: popup.html
[StyledText]: styled_text.html
