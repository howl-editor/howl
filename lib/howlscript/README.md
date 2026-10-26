# Howlscript

Howlscript is the successor to MoonScript for Howl. It keeps what works in
MoonScript, like indentation, implicit returns, classes, comprehensions and
`with`. It adds properties and inherited metamethods to classes. It drops what
doesn't work: `\` method calls, calls without parentheses inside expressions, tables
without braces, `!`, assignment, `if`, `do` and loops as values, function stubs,
`import` and `using`.

Howlscript compiles to Lua for LuaJIT. Its classes have MoonScript's layout, so the
two languages can extend each other's classes during a migration. The compiler in
this directory is plain Lua, with a hand-written lexer and a recursive-descent
parser. Howlscript files use the extension `.howl`.

```howl
{:File} = howl.io

class Note
  new: (@path, @tags = {}) =>

  property title => @path:match('[^/]+$')

  tagged: (tag) => [t for t in *@tags if t == tag]

  save: (text) =>
    file = File(@path)
    file.contents = text unless file.exists
    signal.emit('note-saved', note: self, size: #text)

  __tostring: => "Note(#{@title})"

count = 0
count++
```

**[REFERENCE.md](REFERENCE.md) is the authoritative description of the language**,
including how it differs from MoonScript.

## Compiling

```lua
local howlscript = require('howlscript')
-- on failure: nil, the formatted message, and { line, col, len, message }
local lua, err, details = howlscript.to_lua(source, { chunkname = '@file.howl' })
local f, err = howlscript.loadstring(source, '=name', env)
local f, err = howlscript.loadfile('path/file.howl', env)
howlscript.dofile('path/file.howl', ...)
```

`bin/howlc [-e <code>] [<file>|-]...` prints the Lua for files, snippets or stdin,
and doubles as a syntax check.

**Line alignment:** every statement of the Lua starts on the line where it starts
in the source. Code generated for a line already passed shares the current line. So
runtime errors and tracebacks point at the right `.howl` line without any line
mapping.

**Compile errors** are reported as `file:line:col: message`, followed by the source
line and a caret. The column counts characters. `to_lua` also returns the error as a
table, where `col` is a byte column and `len`, when known, the length in bytes of
the token the error is about.

**In the editor,** the `howlscript` bundle (`bundles/howlscript`) gives `.howl` files
a mode with highlighting and indentation. Its inspector marks compile errors as you
type. `howlscript-print` shows the Lua for the buffer or selection, and
`howlscript-eval` runs the current line or selection.

**Generated names** start with `__hs`, a prefix reserved for the compiler.

## Loading in Howl

Howl loads `.howl` files wherever it loads `.moon` and `.lua` ones:

- **Loaders:** `require`, `bundle_load` (so a bundle's `init.howl` too), the user's
  `init.howl` and `user_load`, and `--run` / `--run-async`.
- **Tools:** `--compile` to `.bc`, specs (`*_spec.howl`), `bin/howl-eval --howl` and
  the howl-dev bundle's compile on save.

`lib/howl/howlscript_support.lua` does this, by hooking the global `loadfile` and
adding a `require` searcher over `package.howlpath`. It loads the compiler with the
first `.howl` file.

When a module exists in more than one form, `.bc` wins, then `.howl`. `require` then
tries `.moon` and `.lua`, while `bundle_load` and the user init try `.lua` before
`.moon`.

There's no Howlscript linter yet, so `--lint` only checks that a `.howl` file
compiles. The existing MoonScript code hasn't been converted.
