---
title: howl.regex
---

# howl.regex

## Overview

Lua, by itself, does not provide regular expression. Instead it provides its own
more limited form of pattern matching. Regular expressions are instead provided
by the howl.regex module as an extension. To blend in with Lua, the operations
provided by the regex module closely mimics the corresponding operations found
in the Lua string standard library. Support for regular expressions is also
included in Howl's [string extensions](ustring.html), making it easy to use
within your code. Since regular expressions are not native to Lua, there's no
syntactical sugar available for constructing a regular expression. Instead
regular expression are constructed as ordinary strings. The global function
[r](#r) provides a constructor function for this. Since this is available in the
global namespace, it's possible to construct a regular expression anywhere
within Howl just by prefixing a string with `r`, like so:

```lua
my_regex = r'\\d+[lL]'
```

You can then either use provided methods directly on the regular expression:

```lua
r'(r\\w+)\\s+(\\S+)':match('red right hand') -- => "red", "right"
```

Or use Howl's [string extensions](ustring.html) which allows for passing in
regular expressions instead of Lua patterns:

```lua
local s = 'red right hand'
s:ufind(r'(\\w+)', 5) -- => 5, 9, "right"
s:umatch(r'(r\\w+)\\s+(\\S+)') -- => "red", "right"
```

Howl's regular expressions are implemented as Perl compatible regular
expressions. While it's an implementation detail, susceptible to change, they
are currently implemented on top of GLibs regular expression support. You can
read more about the full syntax supported by the implementation
[here][glib-regex-syntax].

_See also_:

- The [spec](../spec/regex_spec.html) for regex
- The ["Regular expression syntax"][glib-regex-syntax] page for GRegex

## Properties

### pattern

Holds the regular expression string used to construct the regular expression.

```moonscript
r('\\d+').pattern -- => '\\d+'
```
### capture_count

Holds the the number of capturing groups in the regular expression:

```moonscript
r('foo(bar)(\\w+)').capture_count -- => 2
```

## Functions

### is_instance (v)

Returns true if `v` is a regular expression instance, and false otherwise.

### r (pattern)

Constructs a regular expression from `pattern`. As was noted in the overview,
this is available globally as simple `r`. Raises an error if `pattern` is not a
valid regular expression. This function also accepts regular expressions as
parameters, in which case the passed regular expression is returned as is.

## Methods

### match (string [, init])

Matches the regular expression against `string`. If `init` is specified, starts
matching from that position. Has the same semantics as Lua's [string.match],
with the one significant difference that `init` as well as any returned
positional captures are treated as character offsets.

```lua
r'(r\\w+)\\s+(\\S+)':match('red right hand') -- => "red", "right"
r'()red()':match('red') -- => 1, 4
r'\\pL':find('!äö') -- => 2, 2
```

### find (s [, init])

Finds the first match of the regular expression in `s`, optionally starting at
`init` if specified. Has the same semantics as Lua's [string.find], with the
one significant difference that `init` as well as any returned indices are
treated as character offsets.

```lua
local s = 'red right hand'
s:ufind(r'(\\w+)', 5) -- => 5, 9, "right"
```

### gmatch (s)

Returns an iterator function, where each consecutive call returns the next match
of the regular expression in `s`. Has the same semantics as Lua's
[string.gmatch], with the one significant difference that any positional
captures are returned as character offsets.

```moonscript
[m for m in r'\\w+'\gmatch 'well hello there'] -- => { 'well', 'hello', 'there' }
[p for p in r'()\\s+'\gmatch 'ΘΙΚΛ ΞΟΠ ' ] -- => { 5, 9 }
```

[glib-regex-syntax]: https://developer.gnome.org/glib/stable/glib-regex-syntax.html
[string.match]: http://www.lua.org/manual/5.2/manual.html#pdf-string.match
[string.find]: http://www.lua.org/manual/5.2/manual.html#pdf-string.find
[string.gmatch]: http://www.lua.org/manual/5.2/manual.html#pdf-string.gmatch
