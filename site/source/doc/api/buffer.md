---
title: howl.Buffer
---

# howl.Buffer

## Overview

Buffers are in-memory containers of text. While they are often associated with a
specific file on disk, this need not be the case. Instead they simply represent
some textual content loaded into memory, available for manipulation within Howl.
Buffer manipulation is typically done in one of two ways; it can be done as a
result of a user interacting with an [Editor] displaying a particular buffer, or
it can be done programmatically by manipulating the buffer directly.

Buffers can be created directly and used without being associated with a file or
an [Editor], or without showing up in the buffer list. But if you want the
buffer to show up in the buffer list you need to either create it through, or
register it with, [Application].

_See also_:

- The [spec](../spec/buffer_spec.html) for Buffer
- [Application.new_buffer](application.html#new_buffer)
- [Application.add_buffer](application.html#add_buffer)

## Properties

### can_undo

Whether the buffer contains any undo information that can be undo via the
[undo](#undo) method. You can assign false to clear any undo information
currently available for a particular buffer.

```lua
local buffer = Buffer()
buffer.text = 'my buffer text!'
print(buffer.can_undo)
-- => true
buffer.can_undo = false
print(buffer.can_undo)
-- => false
```

### collect_revisions

Whether modifying operations should collect undo revisions. Defaults to true.

### config

A configuration object that can be used to access and manipulate [config]
variables for a certain buffer. This object is automatically chained to the
buffer's mode's config property, meaning it will defer to what is set for the
mode (and in extension set globally) should a particular configuration variable
not be set specifically for the buffer.

### data

A general-purpose table that can be used for storing arbitrary information about
a particular buffer. Intended as a way for any Howl code to have a place to
assign data with a buffer. Similar to [properties](#properties) but ephemeral,
i.e. any data in this table will be lost upon a restart. As this is shared by
all Howl code, take care to namespace any specific data properly.

### eol

The line ending currently in effect for the buffer. One of:

- `'\n'`
- `'\r\n'`
- `'\r'`

### file

An optional file associated with the current buffer. Assigning to this causes
the buffer to be associated with assigned file, and loaded with the file's
contents. If the file does not exist, the buffer's current contents will be
emptied. The buffer's [title](#title) is automatically updated from the file's
name as part of the assignment.

### last_changed

A timestamp value, as obtained from [howl.sys.time](sys.html#time), specifying
when the buffer was last changed due to any modification operation, such as a
insert or delete. Note that this is not related to any potential [file](#file)
association, but only reflects the buffer's in-memory status.

### last_shown

A timestamp value, as obtained from [howl.sys.time](sys.html#time), specifying
when the buffer was last [showing](#showing).

### length

The length of the buffer's text, in code points.

### lines

An instance of [Lines] for the buffer that allows for line based access to the
content.

### mode

The buffer's [mode]. When assigning to this:

- the `buffer-mode-set` signal is emitted.
- any previously lexed content is re-lexed using the new mode's lexer, if any

### modified

A boolean indicating whether the buffer is modified or not. You can explicitly
assign to this to force a particular status.

### modified_on_disk

For a buffer with an associated file, this is a boolean indicating whether the
file has changed since its contents was loaded into the buffer. Always false for
a buffer without an associated file.

### multibyte

A boolean indicating whether the buffer's text contains multibyte characters.

### properties

A general-purpose table that can be used for storing arbitrary information about
a particular buffer. Intended as a way for any Howl code to have a place where
to store persistent information for a buffer. The contents of this is
automatically serialized and restored with the session. As this is shared by all
Howl code, take care to namespace any specific data properly.

### read_only

A boolean specifying whether the buffer is read-only or not. A read-only buffer
can not be modified. Assign to this to control the status.

### showing

A boolean indicating whether the buffer is currently showing in any editor.

### size

The size of the buffer's text, in bytes.

### text

The buffer's text. Assigning to this causes the entire buffer contents to be
replaced with the assigned text.

### title

The buffer's title. This is automatically set whenever assigning a [file](#file)
to a buffer, but can be explicitly specified as well. Assigning to this causes
the `buffer-title-set` signal to be emitted.

## Functions

### Buffer(mode = {})

Creates a new buffer, optionally specifying its mode.

## Methods

### append(text)

Appends `text` to the end of the buffer's current text.

### as_one_undo(f)

Invokes the function `f`, and collects any modifications performed within `f` as
one undo group. Calling this, and subsequently calling [undo](#undo) will thus
undo all modifications made within `f`.

### byte_offset(char_offset)

Returns the byte offset corresponding to the passed `char_offset`. Raises an
error if `char_offset` is out of bounds.

### char_offset(byte_offset)

Returns the character offset corresponding to the passed `byte_offset`. Raises
an error if `byte_offset` is out of bounds.

### chunk(start_pos, end_pos)

Returns a [Chunk] for the given range.

### context_at(pos)

Returns a [Context] for the specified position.

### delete(start_pos, end_pos)

Deletes the text between `start_pos` and `end_pos`, which specify an inclusive
range.

### find(search, init = 1)

Searches for the text `search` in the the buffer's text starting at character
position `init`. Returns character offsets `start_pos`, `end_pos` of the first
match, or `nil` if no match was found. A negative `init` specifies an offset
from the end, where -1 means the last character of the buffer.

See also: [rfind()](#rfind)

### insert(text, pos)

Inserts `text` at the position given by `pos`, and returns the position right
after newly inserted text. examples.

### lex(end_pos)

Lexes the buffer content using the [mode](#mode)s lexer, if available. The
content is lexed up until `end_pos`, or until the end of the buffer if omitted.

### redo()

Redo the last, previously [undo](#undo)ne, buffer modification.

### reload (force = false)

Reloads the buffer contents from its associated [file](#file). Raises an error
if the buffer does not have any associated file. Emits the `buffer-reloaded`
signal. Returns `true` if the buffer was successfully loaded and `false`
otherwise. A modified buffer will not be reloaded (with `false` being returned),
unless `force` is true.

### replace(pattern, replacement)

Replaces all occurrences of `pattern` with `replacement`, and returns the number
of replacements made. `pattern` can be either a Lua pattern, or a [regular
expression].

### rfind(search, init = @length)

Reverse search: searches backwards for the text `search` in the buffer's text
starting at the character position `init`. Returns character offsets
`start_pos`, `end_pos` of the first match, or `nil` if no match was found. A
negative `init` specifies an offset from the end, where -1 means the last
character of the buffer. The rightmost character of the match found may be at
the `init` position, however, no part of the match will be to the right of
`init`.

See also: [find()](#find)

### save()

Saves the buffer's content to its associated file, if any. Emits the
`buffer-saved` signal. As part of saving the content, optionally removes any
trailing white-space and ensures that there's an eol at the end of the file,
according to the `strip_trailing_whitespace` and `ensure_newline_at_eof`
configuration variables.

### save_as (file)

Associates the buffer with, and saves the buffer's content to `file`. The save
is performed using the same semantics as for [save()](#save).

### sub(start_pos, end_pos)

Returns the text from character offset `start_pos` to `end_pos` (both
inclusive). Returns an empty string when `start_pos` is larger than `end_pos`.
Negative offsets count from end of the buffer.

```lua
local buffer = Buffer('abcde')
print(buffer\sub(1, 2))
-- => 'ab'
print(buffer\sub(-2, -1))
-- => 'de'
```

### undo()

Undo the last buffer modification.

[Application]: application.html
[Lines]: lines.html
[Chunk]: chunk.html
[Context]: context.html
[Editor]: ui/editor.html
[config]: config.html
[mode]: mode.html
[regular expression]: regex.html
