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

### read_async (num, handler)

Reads up to `num` bytes from the input stream, invoking `handler` with the
result. `handler` will receive two parameters, the first being a boolean
indicating whether the read succeded or not. If the read succeded, the second
parameter will be the data read, as a string. Upon end-of-file, this will be
`nil`. If the read failed, the second parameter will be an error string
containing information about the failure.

Note that just as for [read](#read), the actual number of bytes read can be
smaller than `num`. Also note that the name might give the indication that the
alternative, [read](#read), is not asynchronous while `read_async` is. This is
not actually the case, as both are asynchronous in the sense that neither will
block Howl; `read_async` is for the case where you don't want to block execution
flow, e.g. when you need to read from multiple input streams at the same time.
If this is not the case then [read](#read) is likely a better alternative.

### read_all ()

Reads all of the stream's content, returning the result as a string. Raises an
error upon any IO error.
