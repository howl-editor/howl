# Howlscript reference

This is the authoritative description of Howlscript: what the compiler in this
directory accepts, and what it means. [README.md](README.md) introduces the language
and the compiler's API.

Howlscript compiles to Lua for LuaJIT, so its values, operators and standard library
are Lua's. The last section lists how it differs from MoonScript 0.5.0, the version
Howl ships in `lib/ext/moonscript`.

- [Lexical structure](#lexical-structure)
- [Layout](#layout)
- [Values](#values)
- [Assignment and scope](#assignment-and-scope)
- [Functions](#functions)
- [Calls](#calls)
- [Control flow](#control-flow)
- [Comprehensions](#comprehensions)
- [Classes](#classes)
- [Compared with MoonScript](#compared-with-moonscript)

## Lexical structure

### Comments

A comment starts with `--` and runs to the end of the line. There are no block
comments: `--[[` starts an ordinary line comment.

`--` right after a name or `]` is the decrement operator, so a comment after code
needs a space before it: write `x -- note`, not `x--note`.

### Names and keywords

A name is made of ASCII letters, digits and `_`, and doesn't start with a digit.
Names starting with `__hs` are reserved for the compiler.

These are the keywords:

```
and  break  class  continue  do  else  elseif  export  false  for  if  in  local
nil  not  or  return  switch  then  true  unless  when  while  with
```

- `extends` only means something after a class name. Elsewhere it's an ordinary name,
  and so are `import`, `from` and `using`.
- `super` always refers to the parent class (see [Classes](#classes)), so it can't be
  assigned to.
- `self` is an ordinary name, which `=>` declares as a method's first parameter.
- The Lua keywords that Howlscript doesn't use, `end`, `function`, `goto`, `repeat`
  and `until`, can't be variable names.
- Any keyword works as a table key, a field name and a method name: `{end: 1, if: 2}`,
  `t.end`, `assert.true(x)`, `obj:end()`.

### Numbers

Numbers are written as in Lua and LuaJIT: `42`, `3.14`, `.5`, `1e3`, `314.16e-2`,
`0xff`, `0xA23p-4`, and LuaJIT's `10LL`, `10ULL` and imaginary `2i`. A letter or `_`
right after a number is an error, as in `12abc`.

### Strings

- **Quoted strings:** `'single'` and `"double"` quoted strings take Lua's escapes.
  They can span lines, and keep the line breaks.
- **Interpolation:** double quoted strings interpolate `#{expr}`, so `"#{a} + #{b}"` is
  `tostring(a) .. " + " .. tostring(b)`. The expression can hold strings and braces
  of its own, and an empty `#{}` is an error. Single quoted strings don't interpolate.
- **Long strings:** `[[long]]` strings work as in Lua. Their text is used as it is,
  without escapes or interpolation, and a line break right after `[[` is dropped.
  They have no levels (`[==[long]==]`), so text that contains `]]` goes in a quoted
  string.

```howl
name = 'Howl'
greeting = "Hello, #{name}!"
row = 'a\tb\n'
ffi.cdef([[
  int strlen(const char *s);
]])
```

### Operators

Lua's operators, with Lua's precedence, from lowest to highest:

| Operators | Notes |
|---|---|
| `or` | |
| `and` | |
| `<` `>` `<=` `>=` `==` `!=` `~=` | `!=` is an alias for `~=` |
| `..` | right associative |
| `+` `-` | |
| `*` `/` `%` | |
| `not` `#` `-` | unary |
| `^` | right associative |

There are no bitwise operators and no `//`, as LuaJIT has neither; use the `bit`
library. Assignment and its update operators are statements (see
[Assignment and scope](#assignment-and-scope)).

`;`, `\` and `!` aren't used. Each is an error with a hint: statements end at the end
of the line, methods are called with `:`, and functions with `()`.

## Layout

A block is a run of lines indented deeper than the line that opens it, all at the
same indentation. Any amount of indentation works, and a tab counts as four spaces.
A line indented deeper than the block it's in is an error, unless it continues the
line before it.

A statement ends at the end of its line, so there's one statement per line. It
continues on the next line when the line ends with a binary operator, `,`, `=` or an
update operator such as `+=`. The continuation line must be indented deeper than the
line the statement starts on:

```howl
total = price +
  shipping
```

The headers of `if`, `unless`, `elseif`, `while`, `for`, `with`, `switch`, `when` and
`class` end at the end of their line too.

Inside `{ }` and the parentheses of a call, a line break separates entries, like a
comma, and the indentation of the lines doesn't matter. Inside grouping parentheses,
`[ ]` indexes and list comprehensions, a line break is just whitespace.

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

A body can also follow on the same line, as in `-> x + 1`, `if c then a else b`,
`for x in *t do f(x)`, `while c do f()`, `do f()`, `when 1 then a` and `else b`. Inside
call arguments, with or without parentheses, or a table, such a body ends at the first
comma. Elsewhere it can be a list: `f = -> 1, 2` returns two values.

`else` and `elseif` either follow on the same line, or line up with the line where
the `if` starts.

## Values

The values are Lua's: `nil`, `true`, `false`, numbers, strings, tables, functions,
and `...` for the extra arguments of a function that takes them.

A table literal needs braces. Its entries are separated by commas, line breaks or
both, and positional values and keyed entries can come in any order:

```howl
t = {1, 2, name: 'x', [key]: v, 'a b': true, :name}
config = {
  width: 80
  tags: {'a', 'b'}
}
```

- `name: value` sets a key that's a name, and any keyword works as one.
- `'text': value` and `"text": value` set a string key, and `[expr]: value` any key.
- `:name` is short for `name: name`.
- A key needs a space after its colon. `{a:b}` is a method call without arguments,
  which is an error, so write `{a: b}`.
- A nested table needs its braces too: `{a: {b: 1}}`, not `{a: b: 1}`.

The only place a table can leave out its braces is in the trailing named arguments of
a call (see [Calls](#calls)). A `[` that starts a value always starts a list
comprehension (see [Comprehensions](#comprehensions)), so `[1]` is an error.

## Assignment and scope

The first assignment to a name declares a local. Later assignments, including those
inside nested functions, update it:

```howl
a, b = 1, 2
a += 10              -- also -=, *=, /=, %=, ..=, or=, and=
a++                  -- ++ and -- add or subtract 1
t.count--
a, b = b, a
```

- **Targets:** names, fields, indexes, `@x`, `@@x`, `.x` in a `with` block, and
  destructuring patterns. The result of a call can't be assigned to.
- **Update operators:** `+=` and the others, `++` and `--` work on a single target,
  and not on a pattern.
- **A statement:** assignment is not an expression. `a = b = 1` is an error, and so is
  `if x = f()`.

### Visibility

A name becomes visible after the statement that declares it, not in its own
right-hand side. Both `x = x + 1` for a new `x` and a new function that calls itself
refer to a global of the same name. Declare the name first for recursion:

```howl
local fact
fact = (n) -> if n <= 1 then 1 else n * fact(n - 1)
```

A name first assigned inside a block, like the body of an `if`, a loop or a function,
is local to that block. To use it after the block, declare it before with `local`.

### Declarations

- **`local a, b`** declares names up front, for example for functions that call each
  other. `local a, b = 1, 2` also assigns. It can shadow a visible local on purpose.
- **`export a, b`** makes later assignments to those names global, in nested scopes
  too. `export a, b = 1, 2` assigns right away.
- **`export *`** makes every new name in its own scope global, and
  **`export class Foo`** exports a class.

### Destructuring

A table literal used as a target takes values apart by position or key. It works in
assignments, `for` loops and parameters, nests, and can be mixed with other targets.
Its targets can be new or existing names, or fields:

```howl
{:concat, insert: append} = table
{numbers: {first, second}} = config
num, {:message} = result()
{x: point.x, y: point.y} = coords
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
noop = ->
```

- **Arrows:** `->` makes a function. `=>` makes a method, which takes `self` first.
- **Body:** a statement on the same line, or an indented block. A function without
  either is empty.
- **Parameters:** a parameter is one of these:
  - a name;
  - a destructuring pattern;
  - `@x` in a method, which sets `self.x` and also declares the local `x`;
  - `...`, which must be last.
- **Defaults:** any parameter except `...` can have a default, used when the argument
  is `nil`. Parameters are handled in the order they're written, so a default can use
  earlier parameters, and `(@x, y = @x) =>` sees the new `@x`.
- **`...`** is only available in functions that take it, not in functions nested in
  them, and at the top of a file.

### Returning

A function returns the value of its last statement, which can be a list
(`-> a, b`). A trailing loop is the exception: it isn't collected into a table, so in
`-> for x in *t do x` the `x` does nothing, which is an error. Write
`return for x in *t do x`, or use a comprehension.

`return` alone returns nothing. `return if c` returns nothing when `c` holds, while
`return if c then a else b` returns a value.

A file returns the value of its last statement too, so a module can end with its
table: `{:open, :close}`.

### `@` and `@@`

| Form | Means |
|---|---|
| `@` | `self` |
| `@x` | `self.x` |
| `@m(...)` | `self:m(...)` |
| `@@` | `self.__class` |
| `@@x` | `self.__class.x` |
| `@@m(...)` | `self.__class:m(...)` |

They need a `self`: using them outside a method is an error.

## Calls

```howl
print('a', 'b')
obj:method(1)          -- `:` touches both sides
r'\\s+':match(text)    -- a string touching a name is a one-argument call
word = P'x' + S'abc'
'%d items':format(n)   -- literals can be receivers
obj:end()              -- method names can be keywords
make()('a').value:upper()
```

- **Parentheses** must touch the function: `f(x)`, not `f (x)`. A call without
  arguments is `f()`.
- **String calls:** a quoted string touching a name or field is a call with that one
  argument, as in `P'x'` or `t.f"x"`. A long string or a table can't be used like
  that: write `f([[x]])` and `f({a: 1})`, or `f [[x]]` and `f {a: 1}` as statements.
- **Method calls:** `obj:m(args)`. A `:` is a method call when it touches both its
  receiver and the name, and a key separator when followed by a space.
- **No method references:** `obj:m` without a call is an error. Wrap it in a function
  instead: `(...) -> obj:m(...)`.
- **Chains:** `.x`, `[k]`, `(args)`, `:m(args)` and string calls must touch what they
  apply to, so a chain can't be split over lines. A line starting with `.` or `:` is
  a statement of a [`with`](#with) block.

### Named arguments

Trailing `key: value`, `'text': value`, `[expr]: value` and `:name` arguments make up
one table, passed as the last argument. Inside parentheses they can sit on separate
lines:

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

The first argument must be on the same line, after a space. It must also start with
something that can't continue the expression before it:

- a name, number or string;
- `not`, `nil`, `true` or `false`;
- `{`, `@`, `@@`, `#`, `...`, `->` or `=>`;
- `:name` (short for `name: name`) or `.field` (in a `with` block);
- the parameter list of a function, as in `f (x) -> x`.

So `f -1` is a subtraction, and `f (x)` and `f [x]` are errors.

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
for item in *items[2,]
  print(item)
while busy() do wait()
```

### Conditionals

- **`if`** takes any number of `elseif` branches and an optional `else`. A branch's
  body follows `then` on the same line, or is an indented block.
- **`unless c`** is `if not c`. It takes an `else` branch but no `elseif`.
- **Conditions** are expressions, not assignments: `if x = f()` is an error.

### `switch`

`switch value` is followed by `when` clauses on the lines below, indented deeper and
lined up, and optionally by an `else` lined up with them.

- **Values:** a `when` takes one or more values, separated by commas.
- **Matching:** it compares with `==`, with the `when` value on the left. The value
  switched on is evaluated once.
- **Bodies:** the body follows `then` on the same line, or is an indented block, and
  `else` takes its body directly.

### `with`

`with target` evaluates `target` once, and runs the block below it with these
shortcuts:

- **`.x`** is the target's field `x`.
- **`:m(args)`** calls the method `m` on the target. As a statement it can leave out
  its parentheses.
- **Where:** they work in expressions and nested functions too, and in nested `with`
  blocks they refer to the innermost target.

A line starting with `.` or `:` is always such a statement. The target is an
expression, not an assignment, so to name it, assign it first: `file = File(p)`, then
`with file`. Used as a value, a `with` block gives its target.

### Loops

- **Numeric:** `for i = start, stop[, step]`, as in Lua.
- **Generic:** `for a, b in exprs`, as in Lua.
- **Over a list:** `for x in *list` goes over the values of `list`, from 1 to `#list`,
  with a single loop variable. A slice limits it: `*list[start, stop, step]`, where
  each part is optional (`*t[2,]`, `*t[,,2]`). Slices only work here.
- **Destructuring:** loop variables can be patterns: `for {a, b} in *pairs_list`.
- **`while c`** loops while `c` holds.
- **Bodies:** the body follows `do` on the same line, or is an indented block.
- **`break`** leaves the loop, and **`continue`** goes on with the next iteration. It
  compiles to a `goto`.

### Decorators

A statement can end with `if cond`, `unless cond` or `for x in xs [when cond]`:

```howl
print(x) if x
retry() unless done
print(item) for item in *items when item.visible
```

- **Binding:** a decorator binds to the innermost inline body, so in
  `handler: (f) -> open(f) if f` the `if` is part of the function.
- **Assignment:** `x = 1 if c` declares `x` outside the condition.

### Blocks as values

`if`, `unless`, `switch`, `with`, `do`, loops and comprehensions are values:

```howl
label = if count == 1 then 'item' else 'items'
doubled = for x in *list
  continue if x < 0
  x * 2
counter = do
  n = 0
  ->
    n += 1
    n
```

- **`if` and `switch`** give the value of the branch taken, or `nil` when there's
  none.
- **`with`** gives its target.
- **`do`** gives the value of its last statement.
- **Loops** collect the value of their body's last statement on each iteration into a
  list. An iteration ended by `continue` adds nothing.

A block assigned or returned, or the last statement of a function or block, is
compiled in place. Anywhere else in an expression it becomes an immediately called
function. `return`, `break` and `continue` can't be used in such a block, since they
would act on that function.

### Statement checks

- **Dead code:** code after `return`, `break` or `continue` in the same block is an
  error.
- **Useless expressions:** an expression that isn't a call is only allowed as a
  statement where it's a value: the last statement of a function, a file, or a block
  whose value is used.

## Comprehensions

```howl
squares = [x * x for x in *list when x > 0]
points = [{x, y} for x in *xs for y in *ys]
evens = [i for i = 1, 100 when i % 2 == 0]
lookup = {k, true for k in *keys}
inverse = {v, k for k, v in pairs(t)}
pairs_table = {unpack(p) for p in *list_of_pairs}
```

- **List:** `[expr for ...]` collects the values of `expr` into a list.
- **Table:** `{key, value for ...}` sets `key` to `value`. With a single expression,
  `{expr for ...}`, `expr` returns both the key and the value.
- **Clauses:** a comprehension takes one or more `for` clauses of any of the
  [loop](#loops) forms, including slices, and `when` clauses that skip values. They
  nest from left to right.

Comprehension variables follow the shadowing rule (see [Scope](#scope)). A
comprehension used as a statement is an error, since its table is thrown away.

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

- **Declaring:** `class Name` or `class Name extends parent` declares the local
  `Name`, where `parent` is any expression. A class is a statement, not an expression,
  and its name is a plain name, not a field.
- **Members:** `name: value`, `'text': value` and `[expr]: value` add a member, and
  `:name` is short for `name: name`. `@name: value` sets a class variable.
- **Constructor:** `new` is the constructor. A class without one calls its parent's.
- **`super`:**
  - `super(...)` calls the parent's version of the current method (in `new`, the
    parent constructor);
  - `super:m(...)` calls any parent method on self;
  - `super.x` reads from the parent class, and `super` alone is the parent class.

  It only works in the methods of a class that extends another.
- **Class body:** the body can also hold statements, which run with `self` being the
  class. Names assigned in it are locals that every method can see.
- **`__inherited`:** a parent's `__inherited(parent, child)` is called when it's
  extended.

**A class body runs top to bottom.** The class is created at the `class` line, and
its members and statements then run in order. Members are added with `rawset`, since
the parent's base may already have a `__newindex` (Howl's `PropertyObject` adds one).

The classes are laid out exactly as MoonScript's, so Howlscript and MoonScript
classes can extend each other:

- **Class object:** holds `__init`, `__base`, `__name` and `__parent`. Its metatable
  looks names up in the base and then the parent, and calling it creates an instance.
- **Instances:** an instance's metatable is the class's `__base`. The base has
  `__index` set to itself and `__class` pointing at the class, and it inherits from
  the parent's base through its metatable.

## Compared with MoonScript

This compares Howlscript with MoonScript 0.5.0, the version in `lib/ext/moonscript`.

### Changed

| MoonScript | Howlscript |
|---|---|
| `obj\method args` | `obj:method(args)`. Using `\` is an error. |
| `f!` | `f()`. `!` is an error; negate with `not`. |
| `print sum 10, 20`, `x = f a` | `print sum(10, 20)`, `x = f(a)`. Only a call that is a statement of its own can leave out its parentheses, and only one per line (see [Calls without parentheses](#calls-without-parentheses)). |
| `f (a)` passes `(a)` | An error: the `(` must touch the function. `f (x) -> x` still passes a function. |
| `x -1` calls `x(-1)` | A subtraction. |
| Arguments continued on indented lines, nested by indentation | Inside parentheses, where line breaks are free. Without parentheses, arguments only continue after a trailing `,` and can't nest. |
| `f a: 1, 2` | An error: positional arguments come first. |
| `x = a: 1`, `return a: 1`, indented key blocks | `x = {a: 1}`. A table needs braces, except for the trailing named arguments of a call. |
| `@property name: get: => @x` | `@property(name: {get: => @x})`. A nested table always needs its braces. |
| `f{a: 1}` and `f[[text]]` call `f` | Errors: write `f({a: 1})` and `f([[text]])`, or leave out the parentheses with a space in a statement. |
| `x--note` is a comment | A decrement followed by `note`. Write `x -- note`. |
| `unless a ... elseif b` | `unless` takes an `else` but no `elseif`. |
| `f = -> f()` calls the new local `f` | A name isn't visible in its own right-hand side, so this calls a global `f`. Declare it first with `local f`. |
| Parameters and loop variables can shadow locals | An error; rename one of them (see [Scope](#scope)). |
| A class body adds all its members before running its other statements | It runs top to bottom (see [Classes](#classes)). |
| `goto` can be a variable name | An error, like the other Lua keywords Howlscript doesn't use. |
| `import`, `from`, `using` and `extends` are reserved | They're ordinary names; `extends` only means something after a class name. |

Howlscript also reports mistakes that MoonScript 0.5.0 compiles without complaint:

- **Useless expressions:** an expression statement that does nothing, like `x` or
  `a == b`, where MoonScript writes `local _ = x`.
- **Dead code:** code after `return`, `break` or `continue` in the same block.
- **Jumps out of a value block:** `return`, `break` or `continue` in a value block
  that's compiled to a function, where MoonScript returns from the function it
  generates.
- **`...`:** using `...` in a function that doesn't take it.
- **`self`:** using `@` or `@@` with no `self` around, and `@x` parameters in a
  function made with `->`.
- **`super`:** using `super` outside a class method, or in a class without a parent.

### Left out

| MoonScript | Instead |
|---|---|
| `import a, b from t` | `{:a, :b} = t`. Destructuring shows how the names get into scope. |
| `import \m from obj` | `m = (...) -> obj:m(...)` |
| `obj\method` (a function stub) | `(...) -> obj:method(...)`. Stubs hide references and keep objects alive. |
| `(a using b) ->`, `(using nil) ->` | Parameters can't shadow locals, and `local x` declares a fresh local where one is needed. |
| `local *`, `local ^` | `local a, b`, naming each. |
| `export ^` | `export A, B`, naming each. |
| `x = class ...`, `class extends Base` (class expressions and anonymous classes) | A named class statement, then `x = Name`. |
| `class a.B` | `class B`, then `a.B = B`. |
| `if x = f()`, `elseif x = f()` | `x = f()` before the `if`. For `elseif`, nest an `if` in the `else`. |
| `with x = f()` | `x = f()`, then `with x`. |
| `&`, `\|`, `~`, `<<`, `>>`, `//` and `&=`, `\|=`, `<<=`, `>>=` | The `bit` library, as in `bit.band(a, b)`, and `math.floor(a / b)`. MoonScript compiles them to Lua 5.3 operators, which LuaJIT doesn't have. |
| `[==[long]==]` | `[[long]]`, or a quoted string when the text contains `]]`. |

### New

- **`++` and `--`:** `x++` and `t.count--` add or subtract 1, as statements.
- **Destructured parameters:** `({:width, :height}) -> width * height`. MoonScript
  0.5.0 reads this as a call.
- **Imaginary numbers:** LuaJIT's `2i`.
- **Hints:** errors for MoonScript habits like `\`, `!`, `f (x)`, braceless tables,
  `using` and stubs say what to write instead.
