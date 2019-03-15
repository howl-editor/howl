---
title: howl.ui.ActionBuffer
---

# howl.ui.ActionBuffer

## Overview

An ActionBuffer is a specialized kind of [Buffer], that is primarily useful for
creating text-based interfaces. In contrast to ordinary buffers, where styling
is done according to a mode's lexer, styling is manually handled for
ActionBuffers. Since it's an extension of [Buffer], it supports all operations
available for [Buffer], but it extends a few of them to add support for
additional functionality.

---

_See also_:

- The [Buffer] class which ActionBuffer is based upon
- The [spec](../../spec/ui/action_buffer.html) for ActionBuffer


## Functions

### ActionBuffer()

Creates a new ActionBuffer.

## Methods

### append (object, style_name)

Appends `object` at the end of the buffer. `style_name`, when given, allows
specifying the style of the inserted contents (e.g. `keyword`, `number`).

`object` can be either a regular string, or a "styled object" such as a
[StyledText] instance or a [Chunk], in which case the appended content is styled
according to the styles specified for the object and any given `style_name`
parameter is ignored.

### insert (object, position, style_name)

Inserts `object` at `position` given. `style_name`, when given, allows
specifying the style of the inserted contents (e.g. `keyword`, `number`).

`object` can be either a regular string, or a "styled object" such as a
[StyledText] instance or a [Chunk], in which case the inserted content is styled
according to the styles specified for the object and any given `style_name`
parameter is ignored.

### style (start_pos, end_pos, style_name)

Styles a part of the buffer, indicated by the inclusive range
(`start_pos`..`end_pos`), with the style specified in `style_name`.

[Buffer]: ../buffer.html
[Chunk]: ../chunk.html
[StyledText]: styled_text.html
