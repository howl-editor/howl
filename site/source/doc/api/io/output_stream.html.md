---
title: howl.io.OutputStream
---

# howl.io.OutputStream

OutputStreams are used for writing to some kind of IO streams. You don't
typically create an output stream yourself, but instead get one from an another
source, e.g.
[Process.stdin](process.html#stdin).

## Functions

### OutputStream (target, cancellable = nil)

Creates an output stream for `target`, which is either a file descriptor as a
number or an already-constructed gio output stream.

`cancellable` is optional. When given, a pending write or close can be aborted
through it.

## Properties

### is_closed

True if the stream is closed, and false otherwise.

## Methods

### close ()

Closes the output stream.

### flush ()

Flushes any buffered data to the underlying stream.

### write (data)

Writes `data` to the output stream and returns the number of bytes written,
which is always all of it - a short write is retried until everything is out.
Raises an error upon any IO error.
