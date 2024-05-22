---
title: howl.io.OutputStream
---

# howl.io.OutputStream

OutputStreams are used for writing to some kind of IO streams. You don't
typically create an output stream yourself, but instead get one from an another
source, e.g.
[Process.stdin](process.html#stdin).

## Properties

### is_closed

True if the stream is closed, and false otherwise.

## Methods

### close ()

Closes the output stream.

### write (data)

Writes `data` to the output stream. Raises an error upon any IO error.
