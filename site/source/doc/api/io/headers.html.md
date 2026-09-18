---
title: howl.io.headers
---

# howl.io.headers

<div class="alert alert-info" role="alert">
  <strong>Master branch only:</strong>
  This module was added after the 0.6 release. It is available only when running
  Howl from the
  <a class="alert-link" href="https://github.com/howl-editor/howl/tree/master">master branch</a>,
  not in 0.6.
</div>

## Overview

`howl.io.headers` provides the header collection used for HTTP requests and
responses. It is the type you get back from
[Response.headers](http.html#headers).

Header names compare case-insensitively, as HTTP requires, while the casing a
caller used is preserved for sending. Repeated headers are kept as a list rather
than being joined, since joining is wrong for `Set-Cookie` among others.

```moonscript
h = howl.io.headers.create!
h\set 'Content-Type', 'text/plain'
h['content-type']  -- text/plain
h['CONTENT-TYPE']  -- text/plain
```

The module also provides the validation that stops a stray carriage return in a
caller-supplied header from injecting a second header into a request.

_See also_:

- [howl.io.http](http.html)
- The [spec](../../spec/io/headers_spec.html) for headers

## Functions

### create (initial = nil)

Creates a header collection, optionally populated from a table of name/value
pairs.

```moonscript
h = howl.io.headers.create Accept: 'application/json'
```

### is_valid_name (name)

True if `name` is a valid header name - an RFC 9110 token. This excludes
whitespace, `:`, carriage returns and newlines, which is what makes header
injection impossible.

### is_valid_value (value)

True if `value` is acceptable as a header value: a string containing no carriage
return, newline or NUL, and with no leading or trailing whitespace.

### validate_name (name)

Returns `name` if it is valid, and raises otherwise.

### validate_value (name, value)

Returns `value` if it is valid, and raises otherwise. `name` is used only to
make the error message useful.

## Indexing

A collection can be read and written with ordinary table syntax. Reading returns
the **last** value for a repeated header; assigning replaces every existing
value for that name, and assigning `nil` removes it.

```moonscript
h['X-Foo'] = 'bar'
h['x-foo']        -- bar
h['X-Foo'] = nil  -- removed
```

Method names take precedence over headers of the same name on this kind of
lookup. None of them collide with a real HTTP header, but use
[get](#get-name) if you need to be certain.

## Methods

### get (name)

The last value for `name`, or `nil`. Equivalent to indexing.

### set (name, value)

Sets `name` to `value`, replacing any values already present.

### add (name, value)

Adds a value for `name`, keeping any already present. This is how a repeated
header is built.

### remove (name)

Removes every value for `name`.

### has (name)

True if there is at least one value for `name`.

### all (name)

Every value for `name`, in the order they appeared, as a list. Returns an empty
table when the header is absent.

```moonscript
h\add 'Set-Cookie', 'a=1'
h\add 'Set-Cookie', 'b=2'
h\all 'set-cookie'  -- {'a=1', 'b=2'}
```

### count ()

The number of header lines, counting each occurrence of a repeated header
separately.

### each ()

An iterator over every header line, in the order they were added, yielding name
and value. Duplicates are yielded separately, and names come back with the
casing they were set with.

```moonscript
for name, value in h\each!
  print "#{name}: #{value}"
```

### to_table ()

A plain table of the headers with lower-cased names. A repeated header collapses
to its last value, so use [all](#all-name) when that matters.
