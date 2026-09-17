---
title: howl.Chunk
---

# howl.Chunk

## Overview

A Chunk represent a sub part of a [Buffer], and provides a set of operations for
easily manipulating only that buffer section.

_See also_:

- The [spec](../spec/chunk_spec.html) for Chunk

## Properties

### buffer

The corresponding [Buffer] for the chunk

### empty

True if the chunk is empty (i.e. includes zero characters), and false otherwise.

### end_pos

The end position of the chunk. The end position is inclusive, meaning that the
character at `end_pos` is included in the chunk.

### start_pos

The starting position of the chunk.

### styling

A table containing styling information for the chunk. The table contains three
different value for each separate styling element in the chunk; the starting
offset (number), the style applied (string) and the inclusive ending offset
(number). Unlike other position values used within Chunk, these offset are byte
based.

### text

The text for the chunk. As noted in [end_pos](#end_pos), the chunk's range is
inclusive, meaning that the end position is included. For example:

```lua
buffer = howl.Buffer()
buffer.text = 'Liñe 1'
buffer:chunk(2, 4).text -- => 'iñe'
```

Assigning to `.text` replaces the chunk context with the new string. For
example:

```lua
buffer = howl.Buffer()
buffer.text = 'Liñe 1'
buffer:chunk(2, 4).text = 'ua'
buffer.text -- => 'Lua 1'
```

## Methods

### delete ()

Deletes the chunk from the associated [Buffer].

## Meta methods

### \# chunk

Returns the length of the Chunk.

### tostring (chunk)

Returns the [text](.text) of the Chunk.

[Buffer]: buffer.html
