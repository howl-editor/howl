# Serpent

Lua serializer and pretty printer.

## Features

* Human readable:
    * Provides single-line and multi-line output.
    * Nested tables are properly indented in the multi-line output.
    * Numerical keys are listed first.
    * Keys are (optionally) sorted alphanumerically.
    * Array part skips keys (`{'a', 'b'}` instead of `{[1] = 'a', [2] = 'b'}`).
    * `nil` values are included when expected (`{1, nil, 3}` instead of `{1, [3]=3}`).
    * Keys use short notation (`{foo = 'foo'}` instead of `{['foo'] = 'foo'}`).
    * Shared references and self-references are marked in the output.
* Machine readable: provides reliable deserialization using `loadstring()`.
* Supports deeply nested tables.
* Supports tables with self-references.
* Shared tables and functions stay shared after de/serialization.
* Supports function serialization using `string.dump()`.
* Supports serialization of global functions.
* Escapes new-line `\010` and end-of-file control `\026` characters in strings.
* Configurable with options and custom formatters.

## Usage

```lua
local serpent = require("serpent")
local a = {1, nil, 3, x=1, ['true'] = 2, [not true]=3}
a[a] = a -- self-reference with a table as key and value

print(serpent.dump(a)) -- full serialization
print(serpent.line(a)) -- single line, no self-ref section
print(serpent.block(a)) -- multi-line indented, no self-ref section

local fun, err = loadstring(serpent.dump(a))
if err then error(err) end
local copy = fun()
```

## Functions

Serpent provides three functions that are shortcuts to the same
internal function, but set different options by default:

* `dump(a[, {...}])` -- full serialization; sets `name`, `compact` and `sparse` options
* `line(a[, {...}])` -- single line, no self-ref section; sets `sortkeys` and `comment` options
* `block(a[, {...}])` -- multi-line indented, no self-ref section; sets `indent`, `sortkeys`, and `comment` options

## Options

* name (string) -- name; triggers full serialization with self-ref section
* indent (string) -- indentation; triggers long multi-line output
* comment (true/False) -- provide stringified value in a comment
* sortkeys (true/False) -- sort keys
* sparse (true/False) -- force sparse encoding (no nil filling based on #t)
* compact (true/False) -- remove spaces
* fatal (true/False) -- raise fatal error on non-serilizable values
* nocode (true/False) -- disable bytecode serialization for easy comparison
* nohuge (true/False) -- disable checking numbers against undefined and huge values
* custom (function) -- provide custom output for tables

These options can be provided as a second parameter to Serpent functions.

```lua
block(a, {fatal = true})
line(a, {nocode = true})
function todiff(a) return dump(a, {nocode = true, indent = ' '}) end
```

## Formatters

Serpent supports a way to provide a custom formatter that allows to fully
customize the output. For example, the following call will apply
`Foo{bar} notation to its output (used by Metalua to display ASTs):

```lua
print((require "serpent").block(ast, {comment = false, custom =
  function(tag,head,body,tail)
    local out = head..body..tail
    if tag:find('^lineinfo') then
      out = out:gsub("\n%s+", "") -- collapse lineinfo to one line
    elseif tag == '' then
      body = body:gsub('%s*lineinfo = [^\n]+', '')
      local _,_,atag = body:find('tag = "(%w+)"%s*$')
      if atag then
        out = "`"..atag..head.. body:gsub('%s*tag = "%w+"%s*$', '')..tail
        out = out:gsub("\n%s+", ""):gsub(",}","}")
      else out = head..body..tail end
    end
    return tag..out
  end}))
```

## Limitations

* Doesn't handle userdata (except filehandles in `io.*` table).
* Threads, function upvalues/environments, and metatables are not serialized.

## Performance

A simple performance test against `serialize.lua` from metalua, `pretty.write`
from Penlight, and `tserialize.lua` from lua-nucleo is included in `t/bench.lua`.

These are the results from one of the runs:

* nucleo (1000): 0.256s
* metalua (1000): 0.177s
* serpent (1000): 0.22s
* serpent (1000): 0.161s -- no comments, no string escapes, no math.huge check
* penlight (1000): 0.132s

Serpent does additional processing to escape `\010` and `\026` characters in
strings (to address http://lua-users.org/lists/lua-l/2007-07/msg00362.html,
which is already fixed in Lua 5.2) and to check all numbers for `math.huge`.
The seconds number excludes this processing to put it on an equal footing
with other modules that skip these checks (`nucleo` still checks for `math.huge`).

## Author

Paul Kulchenko (paul@kulchenko.com)

## License

See LICENSE file.

## History

Jun 12 2012 v0.12
  - Added options to configure serialization process.
  - Added 'goto' to the list of keywords for Lua 5.2.
  - Changed interface to dump/line/block methods.
  - Changed 'math.huge' to 1/0 for better portability.
  - Replaced \010 with \n for better readability.

Jun 03 2012 v0.10
  - First public release.
