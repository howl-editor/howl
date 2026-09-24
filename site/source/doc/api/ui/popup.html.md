---
title: howl.ui.Popup
---

# howl.ui.Popup

## Overview

Popup is the base class for popups, which display a widget floating above
another widget. It's rarely used directly: the [BufferPopup] displays a buffer,
the [MenuPopup] a list of items to choose from, and the [CompletionPopup] the
completions in an editor.

Popups are normally shown in an editor using the [Editor]'s `show_popup` method.
The editor passes the key presses and edits made while the popup is showing to
the popup, see [Editor hooks](#editor-hooks) below.

---

_See also_:

- The [BufferPopup], [MenuPopup] and [CompletionPopup] classes based on Popup
- The [Editor] API, for showing popups

## Constructor

### Popup (child, opts = {})

Creates a new popup displaying `child`, a Gtk widget. `opts` can contain the
following keys:

- `width`, `height`: The size of the popup, in pixels. A popup needs both of
these to be shown.

Any other keys are set as properties of the underlying Gtk popover.

## Properties

### child

The displayed widget.

### height

The height of the popup, in pixels.

### popover

The underlying Gtk popover.

### showing

Whether the popup is currently showing.

### widget

The widget the popup is showing for, when showing.

### width

The width of the popup, in pixels.

## Methods

### center ()

Centers the showing popup within its widget, shrinking it if necessary to fit.

### close ()

Closes the popup. The popup can be shown again afterwards.

### move_to (pointing_to)

Moves the showing popup to below `pointing_to`, a table with the `x`, `y` and
`height` of the location within the widget to point to.

### release ()

Closes the popup and releases its resources. The popup can not be used
afterwards.

### resize (width, height)

Sets the size of the popup. A showing popup is kept within the monitor, or within
its widget if centered.

### show (widget, options = {position: 'center'})

Shows the popup for `widget`. The popup is shown below the location given as
`pointing_to` in `options` (see [move_to](#move_to-pointing_to)), and centered
within the widget otherwise.

## Editor hooks

A popup shown in an editor can define the following, which the editor uses while
the popup is showing:

### keymap

A [keymap] for handling key presses. A key press handled by the keymap is not
passed on to the editor.

### on_delete_back (editor, args)

Invoked when text before the cursor is deleted in `editor`.

### on_insert_at_cursor (editor, args)

Invoked when text is inserted at the cursor in `editor`.

### on_pos_changed (cursor)

Invoked when the position of the editor's [cursor] changes.

[BufferPopup]: buffer_popup.html
[CompletionPopup]: completion_popup.html
[cursor]: cursor.html
[Editor]: editor.html
[keymap]: ../bindings.html
[MenuPopup]: menu_popup.html
