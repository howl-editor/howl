---
title: howl.ustring (String extensions)
---

# howl.ustring

## Overview

Lua provides string operations in its [string] standard library. While they in
themselves provide a powerful set of tools at your disposal, they have been
supplemented in Howl. To make text strings easier to work with in Howl, strings
are extended with additional methods and properties. For instance, the methods
in Lua's string library operate on the byte level, which make them cumbersome to
use with UTF-8, which is how Howl stores strings internally. To help with this,
Howl provides a complementing set of UTF-8 aware operations. These operations,
apart from being UTF-8 aware, are also aware of Howl's [regular
expressions](regex.html), making these easier to use. Howl also adds properties
to strings, which are accessed through the standard dot notation. Last, Howl
adds the ability to index a string using the standard bracket notation, like so:

```lua
s = 'åäö'
s[1] -- => å
s[-1] -- => ö
```

All of these additional methods and properties are available on all strings,
without the need for constructing special string instances.

Finally, a note on terminology for the Unicode aware: The below documentation of
methods and properties contains references to "characters". In Howl, this
currently means UTF-8 code points, as opposed to glyphs or graphemes.

_See also_:

- The [spec](../spec/ustring_spec.html) for ustring

## Properties

### ulen

The number of characters (code points) in the string.

```lua
('åäö').ulen -- => 3
```

### multibyte

True if the string if the string contains a multibyte UTF-8 sequence, and false
otherwise.

### ulower

A lower case version of the string's content.

```lua
('aBCåÄÖ').ulower -- => 'abcåäö'
```

### uupper

A lower case version of the string's content.

```lua
('abcåäö').uupper -- => 'ABCÅÄÖ'
```

### ureverse

A reversed version of the string's content.

```lua
('öäåcba').ureverse -- => 'abcåäö'
```

### is_empty

True if the string is empty, that is contains zero bytes/characters.

### is_blank

True if the string is "blank", that is contains only blank characters, if any.

## Methods

### byte_offset (...)

Returns byte offsets for all numerical character offsets passed as parameters.
The character offsets, when multiple offsets are passed, must be sorted in
ascending order. If the first argument is a table, a new table is returned
containing all offsets within that table translated. Any out-of-bounds offsets
passed results in an error being raised.

```lua
s = 'äåö'
s:byte_offset(2) -- => 3
s:byte_offset(2, 3) -- => 3, 5
s:byte_offset{2, 3} -- => { 3, 5 }
```

### char_offset (...)

Returns character offsets for all numerical byte offsets passed as parameters.
The byte offsets, when multiple offsets are passed, must be sorted in ascending
order. If the first argument is a table, a new table is returned containing all
offsets within that table translated. Any out-of-bounds offsets passed results
in an error being raised.

```lua
s = 'äåö'
s:char_offset(3) -- => 2
s:char_offset(3, 5) -- => 2, 3
s:char_offset{3, 5} -- => { 2, 3 }
```

### contains (s)

Returns true if the string contains `s`, and false otherwise.

### count (s, pattern = false)

Returns the number of occurrences of `s` within the string. If `pattern` is true,
`s` is evaluated as a Lua pattern. `s` can also be a regex, in which case it's
always evaluated as such, regardless of `pattern`.

### ends_with (s)

Returns true if the string ends with `s`, and false otherwise.

### rfind (text [, init])

Searches backwards for `text` from end of string, or from byte offset `init`, if
provided. Searches for plain strings only (no regex or patterns).  Returns byte
offsets `start_pos`, `end_pos` for the closest match or `nil` when no match was
found.

### split (delimiter)

Splits the string on `delimiter`, returning a table of the parts. `delimiter` is
treated as a lua pattern.

Examples:

```lua
('1'):split(',') -- => { '1' }
('1,2'):split(',') -- => { '2' }
('1,'):split(',') -- => { '1', '' }
('1 , 2'):split(',') -- => { '1 ', ' 2' }
('1 , 2'):split('%s*,%s*') -- => { '1', '2' }
```

### starts_with (s)

Returns true if the string starts with `s`, and false otherwise.

### ucompare (s)

Returns negative, 0 or positive if the string is smaller, equal or greater than
`s`.

### ufind (pattern, [init [, plain]])

Corresponding UTF-8 version of Lua's [string.find]. Unlike the Lua counterpart,
`pattern` can be both a Lua string pattern and a [regex]. If `pattern` is a
regex, it is always evaluated as such regardless of `plain`.

### ugmatch (pattern)

Corresponding UTF-8 version of Lua's [string.gmatch]. Unlike the Lua
counterpart, `pattern` can be both a Lua string pattern and a [regex].

### umatch (pattern [, init])

Corresponding UTF-8 version of Lua's [string.match]. Unlike the Lua counterpart,
pattern can be both a Lua string pattern and a [regex].

### urfind (text [, init])

Similar to ufind() but searches backwards for `text` from end of string, or
character offset `init`, if provided. Searches for plain strings only (no regex
or patterns). Returns character offsets `start_pos`, `end_pos` for the closest
match, or `nil`, if no match was found.

### usub (i [, j])

Corresponding UTF-8 version of Lua's [string.sub].

[glib-regex-syntax]: https://developer.gnome.org/glib/stable/glib-regex-syntax.html
[regex]: regex.html
[string]: http://www.lua.org/manual/5.2/manual.html#6.4
[string.match]: http://www.lua.org/manual/5.2/manual.html#pdf-string.match
[string.find]: http://www.lua.org/manual/5.2/manual.html#pdf-string.find
[string.gmatch]: http://www.lua.org/manual/5.2/manual.html#pdf-string.gmatch
[string.sub]: http://www.lua.org/manual/5.2/manual.html#pdf-string.sub
