---
title: howl.io.InputStream
---

# howl.io.InputStream

InputStreams are used for reading streaming data. You don't typically create an
input stream yourself, but instead get one from an another source, e.g.
[Process.stdout](process.html#stdout).

## Properties

### is_closed

True if the stream is closed, and false otherwise.

## Methods

### close ()

Closes the input stream.

### read (num)

Reads up to `num` bytes from the input stream, returning the result as a string.
The actual number of bytes read can be smaller than `num`. Returns `nil` upon
end-of-file. Raises an error upon any IO error.
