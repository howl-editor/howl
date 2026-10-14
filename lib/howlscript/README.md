# Howlscript

Howlscript is the successor to MoonScript for Howl. It keeps what works in
MoonScript, like indentation, implicit returns, classes, comprehensions and
`with`. It drops what doesn't: `\` method calls, calls without parentheses inside
expressions, tables without braces, `!`, assignment as a value, function stubs,
`import` and `using`.

Howlscript compiles to Lua for LuaJIT. Its classes have MoonScript's layout, so the
two languages can extend each other's classes during a migration. The compiler in
this directory is plain Lua, with a hand-written lexer and a recursive-descent
parser. Howlscript files use the extension `.howl`.

```howl
{:File} = howl.io

class Note extends PropertyObject
  new: (@path, @tags = {}) =>
    super()

  @property(title: {
    get: => @path:match('[^/]+$')
  })

  tagged: (tag) => [t for t in *@tags when t == tag]

  save: (text) =>
    file = File(@path)
    file.contents = text unless file.exists
    signal.emit('note-saved', note: self, size: #text)

count = 0
count++
```

## Differences from MoonScript

| MoonScript | Howlscript |
|---|---|
| `obj\method args` | `obj:method(args)`. Using `\` is an error. |
| `f a, g b`, `x = f a` | `f a, g(b)`, `x = f(a)`. Only a call that is a statement of its own can leave out its parentheses, and only one per line (see [Calls](#calls)). |
| `f!`, `f{}`, `f (a)` | `f()`, `f({})`, `f(a)`. The `(` must touch the function. `!` is an error; negate with `not`. |
| `x = a: 1`, `return a: 1` | `x = {a: 1}`. A table needs braces, except for trailing `key: value` arguments of a call (see [Calls](#calls)). |
| `x += 1` | `x++` and `x--` also work, as statements. |
| `if x = f()` | Assignment is not an expression, so this is an error. |
| `obj\method` (a function stub) | An error: write `(...) -> obj:method(...)`. Stubs hide references and keep objects alive. |
| `import a, b from t` | `{:a, :b} = t`. Destructuring shows how the names get into scope, so there's no `import`, and `import` is an ordinary name. |
| `(x using y) ->`, shadowing | `using` is gone. A parameter or loop variable may not shadow a visible local (see [Scope](#scope)). |
| multi-line arguments by indentation | Arguments are inside parentheses, where line breaks are free. Without parentheses they end with the line. |
| `MyClass.__base` filled first | A class body runs top to bottom (see [Classes](#classes)). |

`local *`, `local ^`, `export ^`, class expressions and anonymous classes are not
supported; Howl doesn't use them.

## Layout

A block is a run of lines indented deeper than the line that opens it. A statement
ends at the end of its line, unless the line ends with a binary operator, `,` or
`=`. The continuation line must then be indented deeper than the statement:

```howl
total = price +
  shipping
```

The headers of `if`, `unless`, `elseif`, `while`, `for`, `with`, `switch`, `when` and
`class` end at the end of their line.

Inside `{ }` and the parentheses of a call, a line break separates entries, like a
comma, and the indentation of the lines doesn't matter. Inside grouping parentheses
and `[ ]` a line break is just whitespace.

A block can open inside brackets. Its lines must be indented deeper than the line
where the enclosing statement or bracket entry starts. The block ends at the first
line indented less, or at a closing bracket:

```howl
signal.connect('buffer-saved', (args) ->
  log.info(args.buffer.title)
)

foo(a, (x) ->
  print(x)
, b)
```

A body on the same line, like `-> x + 1` or `if c then a else b`, ends at the first
comma when it's inside call arguments, with or without parentheses, or a table.
Elsewhere it can be a list: `f = -> 1, 2` returns two values.

`else` and `elseif` either follow on the same line or line up with the line where
the `if` starts. A tab counts as four spaces. Comments start with `--`.

## Values

- **Literals:** `nil`, `true`, `false`, and Lua and LuaJIT numbers (`0xff`, `1e3`,
  `10ULL`).
- **Strings:**
  - `'single'` and `"double"`, with Lua's escapes.
  - Double quoted strings interpolate: `"#{a} + #{b}"` becomes
    `tostring(a) .. " + " .. tostring(b)`.
  - Quoted strings can span lines. `[[long]]` and `[==[long]==]` strings work as in
    Lua.
- **Tables:** `{1, 2, name: 'x', [key]: v, 'a b': true, :name}`. `:name` is short for
  `name: name`. Entries are separated by commas, line breaks or both.
- **Keywords as keys:** any keyword works as a key (`{end: 1, return: 2}`) and as a
  field (`t.end`, `assert.true(x)`).
- **Operators:** Lua's, with Lua's precedence. `!=` is an alias for `~=`. There are
  no bitwise operators; LuaJIT doesn't have them, so use the `bit` library. In
  `x -1` the minus is a subtraction.

## Assignment and scope

The first assignment to a name declares a local. Later assignments, including
assignments inside functions, update it. A name becomes visible after the statement
that declares it, not in its own right-hand side.

```howl
a, b = 1, 2
a += 10              -- also -=, *=, /=, %=, ..=, or=, and=
a++                  -- ++ and -- are statements, not expressions
t.count--
```

`--` right after a name or `]` is the decrement operator. A comment after code
therefore needs a space before it: write `x -- note`, not `x--note`.

More forms:

- `local a, b` declares names up front, for example for functions that call each
  other. It can also shadow a local on purpose.
- `export x, y` makes later assignments to those names global, in nested scopes too.
  `export x = 1` assigns right away. `export *` makes every new name in its own scope
  global, and `export class Foo` exports a class.
- Destructuring takes values apart by position or key, into new or existing
  targets, nested, mixed with other targets, and in `for` loops and parameters:

```howl
{:concat, insert: append} = table
{numbers: {first, second}} = config
num, {:message} = result()
for {left, right} in *pairs_list
  print(left, right)
```

### Scope

A function parameter (including destructured and `@x` ones), a `for` variable or a
comprehension variable may not shadow a local that's visible where it's declared:

```howl
buffer = app.editor.buffer
f = (buffer) -> buffer.text    -- error: parameter 'buffer' shadows the local declared on line 1
```

`_` is exempt, and so is the `self` of a method defined inside another method. An
explicit `local x` may still shadow.

## Functions

```howl
add = (a, b = 1) -> a + b
greet = -> print('hi')
log = (fmt, ...) -> print(fmt:format(...))
render = ({:width, :height} = {width: 1, height: 1}) -> width * height
```

- A function returns the value of its last statement. A trailing loop is the
  exception: it isn't collected into a table.
- `=>` makes a method, taking `self` first.
- `@` is `self` and `@x` is `self.x`. `@m(...)` calls the method `m` on self.
- `@@` is `self.__class`, and `@@x` is a field of the class.
- An `@x` parameter sets `self.x` and also declares the local `x`.
- Parameters are handled in the order they're written: a default can use earlier
  parameters, and `(@x, y = @x) =>` sees the new `@x`.
- `...` is only available in functions that take it, and at the top of a file.

## Calls

```howl
print('a', 'b')
obj:method(1)          -- `:` touches both sides
r'\\s+':match(text)    -- a string touching a name is a one-argument call
word = P'x' + S'abc'
'%d items':format(n)   -- literals can be receivers
obj:end()              -- method names can be keywords
```

Trailing `key: value`, `:name` and `[expr]: value` arguments make up one table,
passed as the last argument. Inside parentheses they can sit on separate lines:

```howl
command.register(
  name: 'open'
  description: 'Opens a file'
  handler: ->
    app:open()
)
howl.config.define(name: 'tab_width', default: 4, :scope)
```

A positional argument can't follow the named ones. A nested table needs its braces:
`@property(title: {get: => @title})`.

A `:` is a method call when it touches both its receiver and the name. It's a key
separator when followed by a space. In `{a:b}` it's a method call without arguments,
which is an error, so a key needs a space after the colon: `{a: b}`.

### Calls without parentheses

A call that is a statement of its own can leave out its parentheses. Its arguments,
named ones included, run to the end of the line, or on to a deeper indented line
after a trailing `,`:

```howl
describe 'Buffer', ->
  it 'inserts text', ->
    buffer:insert 'x', 1
    assert.equal 'x', buffer.text
  VC.register 'git', find: find_git
```

Only one call per line can do this. Calls in its arguments need their parentheses,
and so do calls inside brackets and calls whose value is used. A block opened on the
following lines starts afresh, as in `describe` above.

```howl
assert.equal 1, f(x)                -- not f x
it 'works', -> assert.is_true(ok)   -- not assert.is_true ok
foo(a, -> bar(b))                   -- not bar b
buf = Buffer({})                    -- not Buffer {}
return f(a)                         -- not f a
```

`f -1` is still a subtraction, and `f (x)` and `f [x]` are still errors, while
`f (x) -> x` passes a function.

## Control flow

```howl
if x > 0
  print('positive')
elseif x == 0
  print('zero')
else
  print('negative')

unless done then retry()

kind = switch value
  when 1, 2 then 'small'
  when 3
    'medium'
  else 'large'

with Window()
  .title = 'Notes'
  :show()

for i = 1, 10, 2 do print(i)
for k, v in pairs(t)
  continue if k == 'skip'
  print(k, v)
for item in *items[2,]   -- slices: [start, stop, step], each part optional
  print(item)
while busy() do wait()
```

- **Decorators:** `stmt if cond`, `stmt unless cond` and `stmt for x in xs [when cond]`.
  A decorator binds to the innermost inline body, so in
  `handler: (f) -> open(f) if f` the `if` is part of the function.
  `x = 1 if c` declares `x` outside the condition. `return if c` returns nothing when
  `c` holds, while `return if c then a else b` returns a value.
- **Blocks as values:** `if`, `switch`, `with` (its target), `do`, loops and
  comprehensions are values:

```howl
label = if count == 1 then 'item' else 'items'
doubled = for x in *list
  continue if x < 0
  x * 2
squares = [x * x for x in *list when x > 0]
lookup = {k, true for k in *keys}
pairs_table = {unpack(p) for p in *list_of_pairs}
```

A block assigned or returned is compiled in place. Anywhere else in an expression it
becomes an immediately called function. `return`, `break` and `continue` can't be
used in such a block, since they would act on that function.

- **`switch`** compares with `==`, with the `when` value on the left.
- **`with`:** inside a `with` block, `.x` and `:m()` apply to its target, also inside
  expressions and nested functions. A line starting with `.` or `:` is always such a
  statement, so method chains can't continue on the next line as in MoonScript.
- **`continue`** compiles to a `goto`.
- **Dead code:** code after `return`, `break` or `continue` in the same block is an
  error.
- **Useless expressions:** an expression that isn't a call is only allowed as a
  statement where it's a value, at the end of a function or block.

## Classes

```howl
class Inventory
  new: (@size) =>
    @items = {}
  add: (name) =>
    @items[#@items + 1] = name

class BackPack extends Inventory
  @count: 0                  -- a class variable
  helper = -> 'local to the class body'
  new: (size) =>
    super(size * 2)
    @@count += 1
  add: (name) =>
    error('full') if #@items >= @size
    super(name)
  describe: => 'a backpack, ' .. super:describe()
  :helper                    -- short for helper: helper
  @property(weight: {get: => #@items})  -- class body code runs with self = the class
```

- **Members:** `name: value` defines a member. `new` is the constructor, and a class
  without one calls its parent's.
- **`super`:**
  - `super(...)` calls the parent's version of the current method (in `new`, the
    parent constructor);
  - `super:m(...)` calls any parent method on self;
  - `super.x` reads from the parent class, and `super` alone is the parent class.
- **Class body:** names assigned in a class body are locals that every method can
  see.
- **`__inherited`:** a parent's `__inherited(parent, child)` is called when it's
  extended.

The classes are laid out exactly as MoonScript's, so Howlscript and MoonScript
classes can extend each other:

- **Class object:** holds `__init`, `__base`, `__name` and `__parent`. Its metatable
  looks names up in the base and then the parent, and calling it creates an instance.
- **Instances:** an instance's metatable is the class's `__base`. The base has
  `__index` set to itself and `__class` pointing at the class, and it inherits from
  the parent's base through its metatable.

One thing differs from MoonScript: **a class body runs top to bottom.** MoonScript
fills in all members before running any other class body code. Howlscript creates
the class at the `class` line and then runs members and statements in order, which
keeps the Lua lines aligned with the source. Members are added with `rawset`, since
the parent's base may already have a `__newindex` (Howl's `PropertyObject` adds
one).

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

## Not yet supported

Howl itself doesn't load `.howl` files yet: there's no `require` searcher,
`bundle_load`, `--compile` or user init support. There's also no linter beyond the
compile errors, and the existing MoonScript code hasn't been converted.
