---
title: howl.io.OutputStream
---

# howl.io.OutputStream

OutputStreams are used for writing to some kind of IO streams. You don't
typically create an output stream yourself, but instead get one from an another
source, e.g.
[Process.stdin](process.html#stdin).

## Functions

<div class="alert alert-info" role="alert">
  <strong>Master branch only:</strong>
  Accepting a gio stream and the <code>cancellable</code> argument were added
  after the 0.6 release, and are available only when running Howl from the
  <a class="alert-link" href="https://github.com/howl-editor/howl/tree/master">master branch</a>.
  In 0.6 the constructor took a file descriptor only.
  <a class="alert-link" href="#write-data">write</a> also behaves differently:
  it previously issued a single write, so it could return having written fewer
  bytes than it was given. It now retries until all of the data is out.
</div>

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
