---
title: howl.BufferContext
---

# howl.BufferContext

## Overview

A BufferContext provides contextual information related to a certain position in
a specific buffer. It provides an easy way of retrieving additional information
for a specific position. It is typically used with the current editing position
but could point to any valid location within a buffer. While it's possible to
explicitly create a new context it's more often retrieved using
[Buffer.context_at](buffer.html#context_at), or passed to various handlers.

_See also_:

- The [spec](../spec/buffer_context_spec.html) for BufferContext
- [Buffer.context_at](buffer.html#context_at)

## Properties

### line

Holds the [BufferLines] instance associated with this line.

### next_char

A string containing the current char, if any, or the empty string not available.

```moonscript
b = howl.Buffer!
b.text = 'HƏllo!'
context_at(2).next_char -- => 'Ə'
context_at(7).next_char -- => ''
```

### prefix

A [Chunk] holding the line's text up until the context's position.

```moonscript
b = howl.Buffer!
b.text = '1 3456 89'
context_at(5).prefix.text -- => '1 34'
```

### prev_char

A string containing the previous char, if any, or the empty string not
available.

```moonscript
b = howl.Buffer!
b.text = 'HƏllo!'
context_at(3).prev_char -- => 'Ə'
context_at(1).prev_char -- => ''
```

### style

Holds the name of the style at the context's position, if any, and is `nil`
otherwise.

### suffix

A [Chunk] holding the line's text up starting at the context's position.

```moonscript
b = howl.Buffer!
b.text = '1 3456 89'
context_at(5).suffix.text -- => '56 89'
```

### token

A [Chunk] holding the token at the context's position.

```moonscript
b = howl.Buffer!
b.text = '@!?45xx __'
context_at(1).token.text -- => 'HƏllo'
context_at(4).token.text -- => '45xx'
```

### word

A [Chunk] holding the word at the context's position.

```moonscript
b = howl.Buffer!
b.text = 'HƏllo, said Mr.Bačon'
context_at(2).word.text -- => 'HƏllo'
```

### word_prefix

A [Chunk] holding the current word up until the context's position.

```moonscript
b = howl.Buffer!
b.text = 'HƏllo, said Mr.Bačon'
context_at(3).word.text -- => 'HƏ'
```

[BufferLines]: buffer_lines.html
[Chunk]: chunk.html
