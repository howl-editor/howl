---
title: howl.ui.Selection
---

# howl.ui.Selection

## Overview

A selection is associated with a particular [Editor], and represents the
selection for that editor. It provides operations for obtaining information
about and manipulating the selection. You would never create a Selection
instance yourself; instead you access a selection instance through
[Editor.selection](editor.html#selection).

_See also_:

- The [spec](../../spec/ui/selection_spec.html) for Selection
- The documentation for the [clipboard] module

## Properties

### anchor

The starting point of the selection. If the selection is [empty], it contains
the current cursor position. Assigning to this would create a new selection,
ranging from the assigned position to the cursor's current position.

### cursor

The ending point of the selection, which is the same as the current cursor
position. The character pointed at by cursor is not typically part of the
selection. Assigning to this would manipulate an existing selection.

### empty

True if the selection is empty, and false otherwise.

### includes_cursor

A selection does not typically include the character pointed at by
[cursor](#cursor). If `includes_cursor` is set to true, this is changed
so that the selection always includes the cursor. Default is `false.`

### text

The text of the current selection, or `nil` if the selection is [empty].
Assigning to this property causes the currently selected text to be replaced
with the assigned string and the selection to be removed.

### persistent

A boolean specifying whether the selection is persistent or not. A persistent
selection is automatically extended along with cursor movements, while a
non-persistent selection would be removed upon any cursor movement.

## Methods

### copy (clip_options = {}, clipboard_options)

Copies the current selection to the [clipboard]. If the selection was marked as
[persistent](#persistent), it will be marked as non-persistent as a result of
this call. The `selection-copied` signal is fired as a result of this call.

The optional `clip_options` can specify additional fields for the clipboard
item, and `clipboard_options` any additional options to be passed along to
[clipboard.push].

### cut (clip_options = {}, clipboard_options)

Cuts the current selection to the [clipboard]. If the selection was marked as
[persistent](#persistent), it will be marked as non-persistent as a result of
this call. The `selection-cut` signal is fired as a result of this call.

The optional `clip_options` can specify additional fields for the clipboard
item, and `clipboard_options` any additional options to be passed along to
[clipboard.push].

### range ()

Returns the start and stop offsets for the selection in ascending order, or
`nil` if the selection is [empty].

### remove ()

Removes the selection. Note that this does not remove any content - it's only
the selection itself that is removed. If the selection was marked as
[persistent](#persistent), it will be marked as non-persistent as a result of this call.

### set (anchor, cursor)

Sets the selection, `anchor` and `cursor` in one call.

### select (anchor, pos)

Sets the selection so that the range of characters specified by `anchor` and
`pos` are all included in the selection.

### select_all ()

Selects all the text in the associated editor.

[empty]: #empty
[Editor]: editor.html
[clipboard]: ../clipboard.html
[clipboard.push]: ../clipboard.html#push
