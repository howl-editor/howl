---
title: howl.io.url
---

# howl.io.url

<div class="alert alert-info" role="alert">
  <strong>Master branch only:</strong>
  This module was added after the 0.6 release. It is available only when running
  Howl from the
  <a class="alert-link" href="https://github.com/howl-editor/howl/tree/master">master branch</a>,
  not in 0.6.
</div>

## Overview

`howl.io.url` parses and manipulates URLs. It is a thin layer over GLib's
`GUri`, so it follows RFC 3986 - including the parts that are tedious to get
right by hand, such as resolving a relative reference against a base URL and
handling IPv6 literals.

Parsing returns a plain Lua table, so nothing above this module deals with
C data.

```moonscript
url = howl.io.url
parsed = url.parse 'https://example.com:8443/a/b?q=1#top'
print parsed.host          -- example.com
print parsed.request_target -- /a/b?q=1
```

Functions that can fail return `nil` plus an error message rather than raising,
in the usual Lua style.

_See also_:

- [howl.io.http](http.html), the main consumer of this module
- The [spec](../../spec/io/url_spec.html) for url

## Functions

### parse (s)

Parses an absolute URL, returning a table of its parts. Returns `nil` and an
error message if `s` is not a string, is empty, is relative, is malformed, or
has no host.

The returned table has the following fields:

| Field | Description |
| --- | --- |
| `scheme` | The scheme, lower-cased, e.g. `'https'`. |
| `host` | The host, **without** brackets for an IPv6 literal, e.g. `'::1'`. |
| `port` | The port as a number, defaulted from the scheme when not given explicitly. |
| `default_port` | The default port for the scheme, or `nil` for a scheme we have no default for. |
| `path` | The path, defaulting to `'/'` when the URL carried none. |
| `query` | The query string without the leading `?`, or `nil`. |
| `fragment` | The fragment without the leading `#`, or `nil`. |
| `userinfo` | Any userinfo component, or `nil`. |
| `authority` | Host and port as they belong in a `Host` header - bracketed for IPv6, with the port omitted when it is the scheme default. |
| `request_target` | Path and query, as they belong in a request line. Never includes the fragment. |
| `url` | The normalised URL, with the fragment removed. |

Components are kept percent-encoded, which is what a request line and a `Host`
header need. Use [unescape](#unescape-s) if you want a decoded value.

```moonscript
u = url.parse 'http://[::1]:8080/x'
u.host      -- ::1
u.authority -- [::1]:8080
```

### resolve (base, ref)

Resolves `ref`, which may be relative or absolute, against `base`. `base` is
either a URL string or a table previously returned by [parse](#parse-s). The
result is a table in the same form as [parse](#parse-s), or `nil` plus an error
message.

This is what makes a relative `Location` header work.

```moonscript
url.resolve('https://example.com/a/b/c', 'd').url      -- https://example.com/a/b/d
url.resolve('https://example.com/a/b/c', '../d').url   -- https://example.com/a/d
url.resolve('https://example.com/a/b/c', '/d').url     -- https://example.com/d
url.resolve('https://example.com/a/b/c', '?q=2').query -- q=2
```

### escape (s, reserved = nil, allow_utf8 = true)

Percent-encodes `s`. Characters listed in `reserved` are left alone.

```moonscript
url.escape 'a/b c'      -- a%2Fb%20c
url.escape 'a/b c', '/' -- a/b%20c
```

### unescape (s)

Reverses [escape](#escape-s-reserved-nil-allow_utf8-true), returning `nil` if `s` is not
valid percent-encoded text.

### build_query (params)

Builds a query string from a table, escaping keys and values. Keys are sorted,
so the output for a given table is always the same - which matters for specs and
for anything that caches on a URL.

A list value produces a repeated key.

```moonscript
url.build_query {a: 1, b: 'x y'}   -- a=1&b=x%20y
url.build_query {tag: {'one', 'two'}} -- tag=one&tag=two
```

### bracket (host)

Wraps `host` in brackets if it is an IPv6 literal, and returns it unchanged
otherwise. Parsing strips these brackets, so anything reassembling a host and
port needs to put them back.

```moonscript
url.bracket '::1'         -- [::1]
url.bracket 'example.com' -- example.com
```

## Fields

### DEFAULT_PORTS

A table mapping scheme to default port, currently `http` to 80 and `https` to
443.
