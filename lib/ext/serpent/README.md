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
* Keeps shared tables and functions shared after de/serialization.
* Supports function serialization using `string.dump()`.
* Supports serialization of global functions.
* Supports `__tostring` and `__serialize` metamethods.
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

-- or using serpent.load:
local ok, copy = serpent.load(serpent.dump(a))
print(ok and copy[3] == a[3])
```

## Functions

Serpent provides three functions that are shortcuts to the same
internal function, but set different options by default:

* `dump(a[, {...}])` -- full serialization; sets `name`, `compact` and `sparse` options;
* `line(a[, {...}])` -- single line pretty printing, no self-ref section; sets `sortkeys` and `comment` options;
* `block(a[, {...}])` -- multi-line indented pretty printing, no self-ref section; sets `indent`, `sortkeys`, and `comment` options.

Note that `line` and `block` functions return pretty-printed data structures and if you want to deserialize them, you need to add `return` before running them through `loadstring`.
For example: `loadstring('return '..require('mobdebug').line("foo"))() == "foo"`.

While you can use `loadstring` or `load` functions to load serialized fragments, Serpent also provides `load` function that adds safety checks and reports an error if there is any executable code in the fragment.

* `ok, res = serpent.load(str[, {safe = true}])` -- loads serialized fragment; you need to pass `{safe = false}` as the second value if you want to turn safety checks off.

Similar to `pcall` and `loadstring` calls, `load` returns status as the first value and the result or the error message as the second value.

## Options

* indent (string) -- indentation; triggers long multi-line output
* comment (true/false/maxlevel) -- provide stringified value in a comment (up to `maxlevel` of depth)
* sortkeys (true/false/function) -- sort keys
* sparse (true/false) -- force sparse encoding (no nil filling based on `#t`)
* compact (true/false) -- remove spaces
* fatal (true/False) -- raise fatal error on non-serilizable values
* nocode (true/False) -- disable bytecode serialization for easy comparison
* nohuge (true/False) -- disable checking numbers against undefined and huge values
* maxlevel (number) -- specify max level up to which to expand nested tables
* maxnum (number) -- specify max number of elements in a table
* valignore (table) -- allows to specify a list of values to ignore (as keys)
* keyallow (table) -- allows to specify the list of keys to be serialized. Any keys not in this list are not included in final output (as keys)
* valtypeignore (table) -- allows to specify a list of value *types* to ignore (as keys)
* custom (function) -- provide custom output for tables
* name (string) -- name; triggers full serialization with self-ref section

These options can be provided as a second parameter to Serpent functions.

```lua
block(a, {fatal = true})
line(a, {nocode = true, valignore = {[arrayToIgnore] = true}})
function todiff(a) return dump(a, {nocode = true, indent = ' '}) end
```

Serpent functions set these options to different default values:

* `dump` sets `compact` and `sparse` to `true`;
* `line` sets `sortkeys` and `comment` to `true`;
* `block` sets `sortkeys` and `comment` to `true` and `indent` to `'  '`.

## Metatables with __tostring and __serialize methods

If a table or a userdata value has `__tostring` or `__serialize` method, the method will be used to serialize the value.
If `__serialize` method is present, it will be called with the value as a parameter.
if `__serialize` method is not present, but `__tostring` is, then `tostring` will be called with the value as a parameter.
In both cases, the result will be serialized, so `__serialize` method can return a table, that will be serialize and replace the original value.

## Sorting

A custom sort function can be provided to sort the contents of tables. The function takes 2 parameters, the first being the table (a list) with the keys, the second the original table. It should modify the first table in-place, and return nothing.
For example, the following call will apply a sort function identical to the standard sort, except that it will not distinguish between lower- and uppercase.

```lua
local mysort  = function(k, o) -- k=keys, o=original table
  local maxn, to = 12, {number = 'a', string = 'b'}
  local function padnum(d) return ("%0"..maxn.."d"):format(d) end
  local sort = function(a,b)
    -- this -vvvvvvvvvv- is needed to sort array keys first
    return ((k[a] and 0 or to[type(a)] or 'z')..(tostring(a):gsub("%d+",padnum))):upper()
         < ((k[b] and 0 or to[type(b)] or 'z')..(tostring(b):gsub("%d+",padnum))):upper()
  end
  table.sort(k, sort)
end

local content = { some = 1, input = 2, To = 3, serialize = 4 }
local result = require('serpent').block(content, {sortkeys = mysort})
```

## Formatters

Serpent supports a way to provide a custom formatter that allows to fully
customize the output. The formatter takes four values:

* tag -- the name of the current element with '=' or an empty string in case of array index,
* head -- an opening table bracket `{` and associated indentation and newline (if any),
* body -- table elements concatenated into a string using commas and indentation/newlines (if any), and
* tail -- a closing table bracket `}` and associated indentation and newline (if any).

For example, the following call will apply
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

### v0.28 (May 06 2015)
  - Switched to a method proposed by @SoniEx2 to disallow function calls (#15).
  - Added more `tostring` for Lua 5.3 support (pkulchenko/ZeroBraneStudio#401).
  - Updated environment handling to localize the impact (#15).
  - Added setting env to protect against assigning global functions (closes #15).
  - Updated tests to work with Lua 5.3.
  - Added explicit `tostring` for Lua 5.3 with `LUA_NOCVTN2S` set (pkulchenko/ZeroBraneStudio#401).
  - Fixed crash when not all Lua standard libraries are loaded (thanks to Tommy Nguyen).
  - Improved Lua 5.2 support for serialized functions.

### v0.27 (Jan 11 2014)
  - Fixed order of elements in the array part with `sortkeys=true` (fixes #13).
  - Updated custom formatter documentation (closes #11).
  - Added `load` function to deserialize; updated documentation (closes #9).

### v0.26 (Nov 05 2013)
  - Added `load` function that (safely) loads serialized/pretty-printed values.
  - Updated documentation.

### v0.25 (Sep 29 2013)
  - Added `maxnum` option to limit the number of elements in tables.
  - Optimized processing of tables with numeric indexes.

### v0.24 (Jun 12 2013)
  - Fixed an issue with missing numerical keys (fixes #8).
  - Fixed an issue with luaffi that returns `getmetatable(ffi.C)` as `true`.

### v0.23 (Mar 24 2013)
  - Added support for `cdata` type in LuaJIT (thanks to [Evan](https://github.com/neomantra)).
  - Added comment to indicate incomplete output.
  - Added support for metatables with __serialize method.
  - Added handling of metatables with __tostring method.
  - Fixed an issue with having too many locals in self-reference section.
  - Fixed emitting premature circular reference in self-reference section, which caused invalid serialization.
  - Modified the sort function signature to also pass the original table, so not only keys are available when sorting, but also the values in the original table.

### v0.22 (Jan 15 2013)
  - Added ability to process __tostring results that may be non-string values.

### v0.21 (Jan 08 2013)
  - Added `keyallow` and `valtypeignore` options (thanks to Jess Telford).
  - Renamed `ignore` to `valignore`.

### v0.19 (Nov 16 2012)
  - Fixed an issue with serializing shared functions as keys.
  - Added serialization of metatables using __tostring (when present).

### v0.18 (Sep 13 2012)
  - Fixed an issue with serializing data structures with circular references that require emitting temporary variables.
  - Fixed an issue with serializing keys pointing to shared references.
  - Improved overall serialization logic to inline values when possible.

### v0.17 (Sep 12 2012)
  - Fixed an issue with serializing userdata that doesn't provide tostring().

### v0.16 (Aug 28 2012)
  - Removed confusing --[[err]] comment from serialized results.
  - Added a short comment to serialized functions when the body is skipped.

### v0.15 (Jun 17 2012)
  - Added `ignore` option to allow ignoring table values.
  - Added `comment=num` option to set the max level up to which add comments.
  - Changed all comments (except math.huge) to be controlled by `comment` option.

### v0.14 (Jun 13 2012)
  - Fixed an issue with string keys with numeric values `['3']` getting mixed
    with real numeric keys (only with `sortkeys` option set to `true`).
  - Fixed an issue with negative and real value numeric keys being misplaced.

### v0.13 (Jun 13 2012)
  - Added `maxlevel` option.
  - Fixed key sorting such that `true` and `'true'` are always sorted in
    the same order (for a more stable output).
  - Removed addresses from names of temporary variables (for stable output).

### v0.12 (Jun 12 2012)
  - Added options to configure serialization process.
  - Added `goto` to the list of keywords for Lua 5.2.
  - Changed interface to dump/line/block methods.
  - Changed `math.huge` to 1/0 for better portability.
  - Replaced \010 with \n for better readability.

### v0.10 (Jun 03 2012)
  - First public release.
