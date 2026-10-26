# Howlscript reference

This is the authoritative description of Howlscript: what the compiler in this
directory accepts, and what it means. [README.md](README.md) introduces the language
and the compiler's API.

Howlscript compiles to Lua for LuaJIT, so its values, operators and standard library
are Lua's. The last section lists how it differs from MoonScript 0.5.0, the version
Howl ships in `lib/ext/moonscript`.

In the examples, a comment like `-- 12` gives the value of the expression on its line,
and `-- error: ...` gives the compile error the line causes. Where the Lua is the clearest way to
say what something means, the example shows it. `bin/howlc -e 'code'` prints the Lua
for any snippet.

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

```howl
x = 1 -- a comment, after a space
x--             -- decrements x
t[i]--          -- decrements t[i]
x--note         -- error: unexpected 'note'
```

### Names and keywords

A name is made of ASCII letters, digits and `_`, and doesn't start with a digit.
Names starting with `__hs` are reserved for the compiler.

These are the keywords:

```
and  break  class  continue  do  else  elseif  export  false  for  if  in  local
nil  not  or  return  switch  then  true  unless  when  while  with
```

- `extends` only means something after a class name, and `property` at the start of
  a class item (see [Properties](#properties)). Elsewhere they're ordinary names, and
  so are `import`, `from` and `using`.
- `super` always refers to the parent class (see [Classes](#classes)), so it can't be
  assigned to.
- `self` is an ordinary name, which `=>` declares as a method's first parameter.
- The Lua keywords that Howlscript doesn't use, `end`, `function`, `goto`, `repeat`
  and `until`, can't be variable names.
- Any keyword works as a table key, a field name and a method name: `{end: 1, if: 2}`,
  `t.end`, `assert.true(x)`, `obj:end()`.

```howl
range = {start: 1, end: 10}
print(range.end)  -- 10
end = 10          -- error: 'end' is a Lua keyword and can't be used as a variable name
```

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
summary = "#{#items} items, #{sum(items)} in total"   -- any expression
pattern = '#{x}'           -- single quotes: the text #{x}, as it is
row = 'a\tb\n'
two_lines = 'one
two'                       -- 'one\ntwo'
ffi.cdef([[
  int strlen(const char *s);
]])                        -- the line break right after [[ isn't part of the text
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

As in Lua, the unary operators bind tighter than comparisons, and `^` binds tighter
than unary minus:

```howl
x = not a == b    -- (not a) == b; write a != b
y = -2^2          -- -(2^2), which is -4
```

There are no bitwise operators and no `//`, as LuaJIT has neither; use the `bit`
library, as in `bit.band(flags, 0x4)`, and `math.floor(a / b)`. Assignment and its
update operators are statements (see [Assignment and scope](#assignment-and-scope)).

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
  shipping            -- continues the line before, which ends with +
total = price
  + shipping          -- error: unexpected indentation
```

In the second, `total = price` is a whole statement, so the deeper line after it
continues nothing.

The headers of `if`, `unless`, `elseif`, `while`, `for`, `with`, `switch`, `when` and
`class` end at the end of their line too.

Inside `{ }` and the parentheses of a call, a line break separates entries, like a
comma, and the indentation of the lines doesn't matter. Inside grouping parentheses,
`[ ]` indexes and list comprehensions, a line break is just whitespace.

```howl
size = {
  width: 80           -- the line break separates the entries
  height: 24
}
total = (price
  + shipping)         -- in grouping parentheses, the line break is whitespace
```

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
`for x in *t do f(x)`, `while c do f()`, `do f()`, `when 1 then a` and `else b`. Such
a body is a statement, which runs to the end of the line and can be a list. So
`f = -> 1, 2` returns two values. Inside call arguments or a table, too, it takes the
rest of the line's entries:

```howl
f(-> a, b)            -- passes one function, returning a and b
f((-> a), b)          -- passes a function and b
```

A `,` that ends a line ends such a body, so the entries on the following lines stay
entries. A key after an inline body on the same line, as in `{f: -> 1, g: 2}`, is an
error: put it on a line of its own, or the function in parentheses.

```howl
f(-> a,
  b)                  -- passes a function and b, as the , ends the line
t = {f: -> 1, g: 2}   -- error: the inline body before this key takes the rest of the line, ...
t = {
  f: -> 1
  g: 2
}
```

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

```howl
t = {a:b}       -- error: method reference without a call; ... or add a space after ':' for a key
t = [1]         -- error: expected 'for' in a list comprehension; table literals use {}
```

## Assignment and scope

The first assignment to a name declares a local. Later assignments, including those
inside nested functions, update it:

```howl
count = 0               -- local count = 0
bump = -> count += 1    -- updates the count above
bump()
bump()
print(count)            -- 2
```

An assignment can have several targets and values, and update operators change a
target in place:

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
  and not on a pattern. They evaluate the target's object and key once. Like any
  first assignment, one on a new name declares a local: `count += 1` is
  `local count = count + 1`, reading the global `count`. To update a global, `export`
  its name first (see [Declarations](#declarations)).
- **A statement:** assignment is not an expression. `a = b = 1` is an error, and so is
  `if x = f()`.

### Visibility

A name is new when no local of that name is visible, since assigning to a visible
local updates it. A new name becomes visible after the statement that declares it, so
the right-hand side of `x = x + 1` for a new `x` reads the global `x`. That's how a
global is made local, as in `tonumber = tonumber`. There are two exceptions, where
the new names are visible in their own value:

- **Functions:** when one of the values is a function, so that it can call itself.
- **Blocks:** when the value is a `with` block or a comprehension.

```howl
fact = (n) ->
  return 1 if n <= 1
  n * fact(n - 1)
popup = with Popup()
  .on_close = -> popup:destroy()
```

A table or a parenthesized function isn't an exception: in `t = {get: -> t}`, the `t`
inside is the global one. Parameters and loop variables in the value may
still use the name, as in `names = [names for names in *lists]`. To refer to the
table itself, declare the name first:

```howl
local t
t = {get: -> t}         -- the t inside is this table
```

`local f = value` declares the name after its value, as in Lua, so `f` there is the
outer one even when the value is a function.

A name first assigned inside a block, like the body of an `if`, a loop or a function,
is local to that block. To use it after the block, declare it before with `local`.

```howl
if ready
  state = 'go'          -- a local of the if's body
print(state)            -- the global state, so probably nil

local status
if ready
  status = 'go'         -- updates the local declared before the if
print(status)           -- 'go'
```

### Declarations

- **`local a, b`** declares names up front, for example for functions that call each
  other. `local a, b = 1, 2` also assigns. It can shadow a visible local on purpose.
- **`export a, b`** makes later assignments to those names global, in nested scopes
  too. `export a, b = 1, 2` assigns right away.
- **`export *`** makes every new name in its own scope global, and
  **`export class Foo`** exports a class.

```howl
local is_even, is_odd           -- declared up front, so each can call the other
is_even = (n) -> n == 0 or is_odd(n - 1)
is_odd = (n) -> n != 0 and is_even(n - 1)

export VERSION = '1.0'          -- a global
export setup
setup = -> init()               -- assigns the global setup
```

### Destructuring

A table literal used as a target is a pattern, which takes the value assigned to it
apart. Each entry of the pattern reads one value out of the table and assigns it to
the entry's target:

- **By position:** a plain entry reads the next index, so `{first, second} = t` sets
  `first` to `t[1]` and `second` to `t[2]`.
- **By key:** `key: target` reads `t.key`, and `:name` is short for `name: name`.
  String and expression keys work too, as in `'a b': x` and `[k]: y`.
- **Nesting:** a target can be a pattern itself, which takes apart the value read for
  it.
- **Targets:** new or existing names, fields and indexes. New names are declared as
  locals, as in any assignment.

```howl
{:concat, insert: append} = table   -- concat = table.concat, append = table.insert
{numbers: {first, second}} = config -- config.numbers[1] and config.numbers[2]
num, {:message} = result()          -- the first value, and the second value's message
{x: point.x, y: point.y} = coords   -- sets fields of point
{'a b': spaced, [key]: value} = t
```

The value is evaluated once, and each target reads its own path out of it, so
`{numbers: {first, second}, :name} = load_config()` compiles to the equivalent of:

```lua
local first, second, name
do
  local obj = load_config()
  first, second, name = obj.numbers[1], obj.numbers[2], obj.name
end
```

A value missing from the table gives `nil`. Taking apart `nil` itself is an error when
it runs, as indexing `nil` is in Lua.

Patterns work in three places:

- **Assignments**, as above, where they can be mixed with other targets.
- **Parameters**, where the pattern takes the argument apart (see
  [Destructured parameters](#destructured-parameters)).
- **`for` loops**, where it takes each value apart:

```howl
for {left, right} in *{{1, 2}, {3, 4}}
  print(left + right)               -- 3, then 7
for i, {:name} in ipairs(people)
  print(i, name)
```

### Scope

A function parameter (including destructured and `@x` ones), a `for` variable or a
comprehension variable may not shadow a local that's visible where it's declared:

```howl
buffer = app.editor.buffer
f = (buffer) -> buffer.text    -- error: parameter 'buffer' shadows the local declared on line 1
```

`_` is exempt, and so is the `self` of a method defined inside another method. An
explicit `local x` may still shadow, since it says so:

```howl
f = (buf) -> buf.text                 -- fine: a different name
for _, entry in ipairs(entries)
  for _, tag in ipairs(entry.tags)    -- _ can be reused
    print(tag)
g = ->
  local buffer = other_buffer         -- shadows on purpose
  buffer.text
```

## Functions

```howl
add = (a, b = 1) -> a + b                     -- add(2) is 3
greet = -> print('hi')
log = (fmt, ...) -> print(fmt:format(...))
area = ({:width, :height}) -> width * height  -- area({width: 3, height: 4}) is 12
noop = ->
```

- **Arrows:** `->` makes a function. `=>` makes a method, which takes `self` first.
- **Body:** a statement on the same line, or an indented block. A function without
  either is empty.
- **Parameters:** a parameter is one of these:
  - a name;
  - a destructuring pattern (see [Destructured parameters](#destructured-parameters));
  - `@x` in a method, which sets `self.x` and also declares the local `x`;
  - `...`, which must be last.
- **Defaults:** any parameter except `...` can have a default, used when the argument
  is `nil`. Parameters are handled in the order they're written, so a default can use
  earlier parameters, and `(@x, y = @x) =>` sees the new `@x`.
- **`...`** is only available in functions that take it, not in functions nested in
  them, and at the top of a file.

```howl
pad = (s, width = #s + 2, fill = ' ') -> s .. fill:rep(width - #s)
pad('ab')               -- 'ab  ', as width defaults to #s + 2
pad('ab', nil, '-')     -- 'ab--': a nil argument gets the default too

log_later = (fmt, ...) ->
  args = {...}          -- the function below can't use ..., so keep the values
  -> print(fmt:format(unpack(args)))
```

### Destructured parameters

A destructuring pattern as a parameter takes its argument apart, as assigning the
argument to the pattern would (see [Destructuring](#destructuring)). It's still a
single parameter, so the caller passes one table for it:

```howl
area = ({:width, :height}) -> width * height
area({width: 3, height: 4})                 -- 12
area(width: 3, height: 4)                   -- 12, with named arguments (see Calls)

send = ({:sender, :recipient, body: msg}) -> "#{sender} -> #{recipient}: #{msg}"
send({sender: 'ann', recipient: 'bo', body: 'hi'})   -- 'ann -> bo: hi'

distance = ({x1, y1}, {x2, y2}) -> math.abs(x2 - x1) + math.abs(y2 - y1)
distance({1, 1}, {4, 5})                    -- 7
```

`area` compiles to a function of one argument, which is taken apart before the body
runs:

```lua
area = function(__hs_arg1)
  local width, height = __hs_arg1.width, __hs_arg1.height
  return width * height
end
```

A default applies to the whole argument, before it's taken apart. So
`render = ({:width, :height} = {width: 1, height: 1}) -> width * height` can be called
as `render()`, giving 1. Without a default, calling `area()` is an error when it
runs, as `nil` can't be taken apart.

The names a pattern declares are parameters, so they follow the shadowing rule (see
[Scope](#scope)).

### Returning

A function returns the value of its last statement when that's an expression, such
as a call, a value, a `with` block or a comprehension, or a list of them (`-> a, b`).
A statement without a value, such as an assignment, returns nothing.

```howl
pair = -> 1, 2                    -- returns 1 and 2
double = (x) -> x * 2             -- returns x * 2
store = (t, v) -> t.value = v     -- returns nothing: an assignment has no value
```

`if`, `unless`, `switch`, `do` and loops have no value (see
[Blocks as values](#blocks-as-values)). So a function ending in an `if`, `unless`,
`switch` or `do` returns only what its body returns with `return`, and a value or a
call ending one of its branches is an error, since it would look returned:

```howl
sign = (n) ->
  if n < 0
    -1            -- error: the 'if' ending this function gives no value, so write 'return' before this to return it
  else
    1
```

Write `return` where a value is meant to be returned. When nothing is, end the
function with a bare `return`, which makes the `if` no longer the last statement:

```howl
sign = (n) ->
  if n < 0
    return -1
  elseif n > 0
    return 1
  else
    return 0

report = (ok) ->
  if ok
    log.info('done')
  else
    log.error('failed')
  return          -- without it, both calls are errors
```

A statement modifier is different: `(v) -> f(v) if v` returns `f(v)` when `v` holds,
and nothing otherwise (see [Statement modifiers](#statement-modifiers)).

`return` alone returns nothing, and `return if c` returns nothing when `c` holds.

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

```howl
class Counter
  @made: 0                -- a class variable, Counter.made
  new: (@step = 1) =>     -- sets self.step, and declares the local step
    @@made += 1           -- self.__class.made
    @value = 0
  bump: => @value += @step
  twice: =>
    @bump()               -- self:bump()
    @bump()
    @value

print(Counter(2):twice()) -- 4
print(Counter.made)       -- 1
```

They need a `self`: using them outside a method is an error.

```howl
f = -> @x                 -- error: '@' refers to self, but there's none here; methods are defined with '=>'
```

## Calls

```howl
print('a', 'b')
obj:method(1)          -- `:` touches both sides
r'\\s+':match(text)    -- a string touching a name is a one-argument call
word = P'x' + S'abc'
types = word {'int', 'char'}   -- so is a table after a name
'%d items':format(n)   -- literals can be receivers
obj:end()              -- method names can be keywords
make()('a').value:upper()
```

- **Parentheses** must touch the function: `f(x)`, not `f (x)`. A call without
  arguments is `f()`.
- **String calls:** a quoted string touching a name or field is a call with that one
  argument, as in `P'x'` or `t.f"x"`. A long string can't be used like that: write
  `f([[x]])`, or `f [[x]]` as a statement.
- **Table calls:** a table literal after a name, a field or a method name is a call
  with that one argument, as in Lua, with or without a space: `word {'if', 'else'}`,
  `t.f{a: 1}`, `obj:m {a: 1}`. The table must start on the same line. At the start
  of a statement, a table after a space starts the arguments of a
  [call without parentheses](#calls-without-parentheses) instead, so only there does
  `f {a}, b` pass both values to `f`:

  ```howl
  f {a}, b          -- f({a}, b)
  x = f {a}, b      -- x = f({a}), with b left over
  ```
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

The last call is `howl.config.define({name = 'tab_width', default = 4, scope = scope})`
in Lua. Positional arguments come first, so `f(a, b, key: 1)` is `f(a, b, {key = 1})`,
and a positional argument can't follow the named ones. A nested table needs its
braces: `@property(title: {get: => @title})`.

With a [destructured parameter](#destructured-parameters), named arguments work like
keyword arguments:

```howl
area = ({:width, :height}) -> width * height
area(width: 3, height: 4)       -- 12
area(width: 3, 4)               -- error: positional arguments must come before the named ones
```

### Calls without parentheses

A call that is a statement of its own can leave out its parentheses. Its arguments,
named ones included, run to the end of the line, or on to a deeper indented line
after a trailing `,`:

```howl
describe 'Buffer', ->
  it 'inserts text', ->
    buffer:insert 'x', 1
    assert.equal 'x', buffer.text
    assert.same {'x', 'y'},
      lines                     -- continues after the trailing ,
  VC.register 'git', find: find_git
```

Only one call per line can do this. Calls in its arguments need their parentheses,
and so do calls inside brackets and calls whose value is used. That way it's always
clear which arguments belong to which call. A block opened on the following lines
starts afresh, as in `describe` above. Calls with a table as their only argument
are the exception, as their argument is always clear (see [Calls](#calls)).

```howl
assert.equal 1, f(x)                -- not f x
it 'works', -> assert.is_true(ok)   -- not assert.is_true ok
foo(a, -> bar(b))                   -- not bar b
buf = Buffer(mode)                  -- not Buffer mode
return f(a)                         -- not f a
assert.same {1}, f {1}              -- assert.same({1}, f({1}))
```

The first argument must be on the same line, after a space. It must also start with
something that can't continue the expression before it:

- a name, number or string;
- `not`, `nil`, `true` or `false`;
- `{`, `@`, `@@`, `#`, `...`, `->` or `=>`;
- `:name` (short for `name: name`) or `.field` (in a `with` block);
- the parameter list of a function, as in `f (x) -> x`.

So `f -1` is a subtraction, and `f (x)` and `f [x]` are errors.

```howl
n = f -1        -- f - 1
print (x)       -- error: no space is allowed between a function and the '(' of its call, as in f(x)
print x, -1     -- print(x, -1): the first argument starts with a name
```

## Control flow

```howl
if x > 0
  print('positive')
elseif x == 0
  print('zero')
else
  print('negative')

unless done then retry()

switch value
  when 1, 2 then print('small')
  when 3
    print('medium')
  else print('large')

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
- **No value:** `if`, `unless` and `switch` are statements, and give no value. So
  `label = if n == 1 then 'item' else 'items'` is an error: assign or return in the
  branches instead, or use `and` and `or` when the value can't be false or nil:
  `label = n == 1 and 'item' or 'items'`. This holds at the end of a function too
  (see [Returning](#returning)).

```howl
label = if n == 1 then 'item' else 'items'  -- error: 'if' is a statement and gives no value; ...

local label           -- declared first, as a name first assigned in a branch is local to it
if n == 1
  label = 'item'
else
  label = 'items'

label = n == 1 and 'item' or 'items'   -- or this, as neither value is false or nil
```

### `switch`

`switch value` is followed by `when` clauses on the lines below, indented deeper and
lined up, and optionally by an `else` lined up with them.

- **Values:** a `when` takes one or more values, separated by commas.
- **Matching:** it compares with `==`, with the `when` value on the left. The value
  switched on is evaluated once.
- **Bodies:** the body follows `then` on the same line, or is an indented block, and
  `else` takes its body directly.
- **No value:** like `if`, a `switch` is a statement and gives no value.

```howl
local kind
switch next_token()           -- called once
  when 'if', 'unless'         -- 'if' == value or 'unless' == value
    kind = 'conditional'
  when 'for', 'while' then kind = 'loop'
  else kind = 'other'
```

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

```howl
button = with Button('OK')
  .width = 80                         -- button.width = 80
  :on 'click', -> .label = 'Clicked'  -- button:on(...), and .label is button.label

with window
  .title = 'Notes'                    -- window.title
  with .status_bar
    .text = 'Ready'                   -- window.status_bar.text
```

### Loops

- **Numeric:** `for i = start, stop[, step]`, as in Lua.
- **Generic:** `for a, b in exprs`, as in Lua.
- **Over a list:** `for x in *list` goes over the values of `list`, from 1 to `#list`,
  with a single loop variable. `list` and its length are taken once, before the loop,
  so values added to `list` in the body aren't visited. A slice limits it:
  `*list[start, stop, step]`, where each part is optional (`*t[2,]`, `*t[,,2]`). A
  negative stop counts from the end, as `#list + stop`, so `*t[1, -1]` leaves out the
  last value. Slices only work here.
- **Destructuring:** loop variables can be patterns: `for {a, b} in *pairs_list`.
- **`while c`** loops while `c` holds.
- **Bodies:** the body follows `do` on the same line, or is an indented block.
- **`break`** leaves the loop, and **`continue`** goes on with the next iteration. It
  compiles to a `goto`.
- **No value:** a loop is a statement and gives no value; a comprehension collects
  values.

With `t = {10, 20, 30, 40, 50}`:

| Loop | Goes over |
|---|---|
| `for x in *t` | 10, 20, 30, 40, 50 |
| `for x in *t[2,]` | 20, 30, 40, 50 |
| `for x in *t[,,2]` | 10, 30, 50 |
| `for x in *t[1, -1]` | 10, 20, 30, 40 |
| `for x in *t[2, -2]` | 20, 30 |

`s = t[1, 2]` is an error, as slices only work in loops and comprehensions.

### Statement modifiers

A statement can end with a modifier: `if cond`, `unless cond`, or `for x in xs`, which
can filter with an `if` or `unless` of its own:

```howl
print(x) if x
retry() unless done
print(item) for item in *items if item.visible
```

Modifiers are separate from the `if` and `unless` statements, and apply to the whole
statement:

- **Values:** a modified expression at the end of a function is returned when the
  condition holds, so `(v) -> v if v` returns `v`, or nothing.
- **Statements:** `return x if c` returns only when `c` holds, and `x = 1 if c`
  assigns only then. It declares `x` outside the condition, where it can be used.
- **Binding:** a modifier binds to the innermost inline body, so in
  `handler: (f) -> open(f) if f` the `if` is part of the function.

```howl
label = 'item' if n == 1      -- local label; if n == 1 then label = 'item' end
print(label)                  -- 'item', or nil
first = (t) -> t[1] if t      -- returns t[1] when t holds, and nothing otherwise
```

### Blocks as values

Only `with` blocks and comprehensions are values. A `with` block gives its target,
and a comprehension the table it builds:

```howl
window = with Window()
  .title = 'Notes'
doubled = [x * 2 for x in *list if x >= 0]
```

`if`, `unless`, `switch`, `do` and loops are statements, and give no value: using one
as a value is an error. A `do` block runs its body in a scope of its own.

A `with` block or comprehension assigned or returned, or the last statement of a
function, is compiled in place. Anywhere else in an expression it becomes an
immediately called function. `return`, `break` and `continue` can't be used in such a
block, since they would act on that function.

```howl
n = count([x for x in *list if x > 1])  -- an argument, so a function called in place
show = (t) ->
  display(with t
    return if .hidden   -- error: 'return' can't be used here, as the expression it's in is compiled to a function; ...
    .shown = true
  )
```

### Statement checks

- **Dead code:** code after `return`, `break` or `continue` in the same block is an
  error.
- **Useless expressions:** an expression that isn't a call is only allowed as a
  statement where it's a value: the last statement of a function, a file, or a block
  whose value is used. The last statement in the body of an `if`, `unless`,
  `switch`, `do` or loop isn't such a place.

```howl
a == b                -- error: this expression does nothing; only calls can be statements
f = ->
  return 1
  print('never')      -- error: unreachable code after 'return'
```

## Comprehensions

```howl
list = {3, -1, 4}
squares = [x * x for x in *list if x > 0]         -- {9, 16}
odds = [i for i = 1, 9 unless i % 2 == 0]         -- {1, 3, 5, 7, 9}
lookup = {k, true for k in *{'a', 'b'}}           -- {a: true, b: true}
inverse = {v, k for k, v in pairs({x: 1, y: 2})}  -- {'x', 'y'}: 1 maps to 'x', 2 to 'y'
pairs_table = {unpack(p) for p in *{{'a', 1}, {'b', 2}}}  -- {a: 1, b: 2}
```

- **List:** `[expr for ...]` collects the values of `expr` into a list.
- **Table:** `{key, value for ...}` sets `key` to `value`. With a single expression,
  `{expr for ...}`, `expr` returns both the key and the value.
- **Clauses:** a comprehension takes a single `for` clause, of any of the
  [loop](#loops) forms, including slices. An `if` or `unless` after it skips values.
  A second `for` or filter is an error: nest `for` loops to go over several lists, and
  combine conditions with `and`.

```howl
cells = [{x, y} for x in *xs for y in *ys]  -- error: a comprehension takes a single 'for'; ...

cells = {}
for x in *xs
  for y in *ys
    cells[#cells + 1] = {x, y}
```

Comprehension variables follow the shadowing rule (see [Scope](#scope)). A
comprehension used as a statement is an error, since its table is thrown away.

## Classes

```howl
class Inventory
  new: (@size) =>
    @items = {}
  add: (name) =>
    @items[#@items + 1] = name
  describe: => "#{#@items} of #{@size}"

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
  property weight => #@items
  __tostring: => "BackPack(#{@size})"
  @sizes = {'small', 'large'}  -- class body code runs with self = the class

pack = BackPack(1)           -- size 2, as BackPack's new doubles it
pack:add('map')
print(pack.weight)           -- 1, through the property
print(pack:describe())       -- 'a backpack, 1 of 2'
print(pack)                  -- 'BackPack(2)', through __tostring
print(BackPack.count)        -- 1
```

- **Declaring:** `class Name` or `class Name extends parent` declares the local
  `Name`, where `parent` is any expression. A class is a statement, not an expression,
  and its name is a plain name, not a field.
- **Members:** `name: value`, `'text': value` and `[expr]: value` add a member, and
  `:name` is short for `name: name`. `@name: value` sets a class variable, such as a
  class method.
- **Constructor:** `new` is the constructor. A class without one calls its parent's.
- **`super`:**
  - `super(...)` calls the parent's version of the current method: in `new` the
    parent constructor, in a class method `@name:` the parent class's `name`, and in
    an accessor the parent's accessor (see [Properties](#properties));
  - `super:m(...)` calls any parent method on self;
  - `super.x` reads from the parent class, and `super` alone is the parent class.

  It works in the methods of a class that extends another, including functions
  inside them. A member keyed by an expression evaluates the key again for `super()`.
- **Class body:** the body can also hold statements, which run with `self` being the
  class. Names assigned in it are locals that every method can see.
- **`__inherited`:** a parent's `__inherited(parent, child)` is called when it's
  extended.

The forms of `super`:

```howl
class Shape
  @create: (kind) => "shape #{kind}"
  area: => 0
  name: 'shape'

class Square extends Shape
  @create: (kind) => super(kind) .. '!'  -- Square:create('x') is 'shape x!'
  new: (@side) =>
  area: => @side * @side + super()       -- Shape's area, on self
  describe: => "#{super.name}, #{super:area()}"   -- 'shape, 0'
```

`__inherited` is a class method of the parent, so it runs with the parent as `self`:

```howl
class Plugin
  @registry: {}
  @__inherited: (child) => @registry[#@registry + 1] = child.__name

class Spell extends Plugin
print(Plugin.registry[1])    -- 'Spell'
```

**A class body runs top to bottom.** The class is created at the `class` line, and
its members and statements then run in order. Members are added with `rawset`, since
the parent's base may already have a `__newindex`.

```howl
class Config
  defaults = {width: 80}
  width: defaults.width      -- 80, as defaults is already assigned
```

MoonScript adds the members first, so there `defaults` is still nil at that point.

### Properties

```howl
class Chunk
  new: (@buffer, @start_pos, @end_pos) =>

  property empty => @end_pos < @start_pos

  property text
    get: => @buffer:sub(@start_pos, @end_pos)
    set: (text) =>
      @buffer:replace(@start_pos, @end_pos, text)

chunk = Chunk(buffer, 1, 5)
print(chunk.empty)    -- false, from the getter
print(chunk.text)     -- the text from 1 to 5, from the getter
chunk.text = 'howdy'  -- replaces it, through the setter
chunk.empty = true    -- fails when it runs: property 'empty' is read-only
```

- **Read-only:** `property name => body` declares a property with a getter. The
  getter takes no parameters, and its body is inline or a block.
- **With a block:** `property name` followed by an indented block declares a
  property with `get:` and `set:`, either of which can be left out. Each takes an
  expression, normally a method: the getter takes no parameters, and the setter
  takes the value.
- **Use:** reading a property calls its getter, and assigning to it calls its setter.
  So `new: (@text) =>` goes through the setter too. Setters, like constructors,
  return nothing.
- **Errors:** assigning to a property without a setter is an error,
  `property 'x' is read-only`. So is reading one without a getter,
  `property 'x' is write-only`. Both are reported where the property is used.
- **Inheritance:**
  - A subclass inherits its parent's properties.
  - A property of the same name replaces the parent's, both accessors.
  - In an accessor, `super()` calls the parent's getter, and `super(value)` its
    setter.
- **Names:**
  - A property wins over a method or member of the same name, also in a subclass.
  - Within one class, a name can't be both.
  - `property` only means this at the start of a class item, followed by a name.
    Elsewhere it's an ordinary name, so `property: value` and `@property(...)`
    still work.

```howl
class Named
  new: (name) => @name = name
  property name
    get: => @_name
    set: (name) => @_name = name

class Shouting extends Named
  property name
    get: => super():upper()             -- the parent's getter
    set: (name) => super("<#{name}>")   -- the parent's setter

print(Shouting('ann').name)             -- '<ANN>'
```

### Metamethods

Members named after Lua's metamethods are metamethods of the instances: `__tostring`,
`__eq`, `__lt`, `__le`, `__len`, `__concat`, `__call`, `__unm`, `__add`, `__sub`,
`__mul`, `__div`, `__mod`, `__pow`, `__pairs`, `__ipairs`, `__mode` and `__gc`.
Subclasses inherit them. A subclass's copy is the same function, so an `__eq`
compares the instances of a class and its subclasses.

```howl
class Vec
  new: (@x, @y) =>
  __add: (other) => Vec(@x + other.x, @y + other.y)
  __eq: (other) => @x == other.x and @y == other.y
  __tostring: => "(#{@x}, #{@y})"

class Vec3 extends Vec
  new: (x, y, @z = 0) => super(x, y)

print(Vec(1, 2) + Vec(3, 4))      -- '(4, 6)'
print(Vec3(1, 2))                 -- '(1, 2)', as Vec3 inherits __tostring
print(Vec3(1, 2) == Vec(1, 2))    -- true, as both have the same __eq
```

`__index:` and `__newindex:` are fallbacks:

- **`__index:`** is called with the key, as in `(key) =>`, for a key that the
  instance doesn't have as a field, property or method.
- **`__newindex:`** is called with the key and the value for an assignment to a key
  that isn't a field of the instance or a property. Without it, the assignment sets
  a field.
- **Tables:** either can be a table instead, which the key is read from or set in.
- **New fields:** setting a new field in `new` goes through `__newindex:` too, so set
  those with `rawset(self, key, value)`.
- **Inheritance:** subclasses inherit the fallbacks.
- **Metatable:** they're called by the base's real `__index` and `__newindex`
  functions, so `getmetatable(obj).__index` isn't the fallback.

```howl
class Window
  new: (win) => rawset(self, 'win', win)
  property title => @win.title
  __index: (key) => @win[key]

w = Window({title: 'Notes', width: 80})
print(w.title)          -- 'Notes', through the property
print(w.width)          -- 80, through the fallback
```

### Layout

The classes are laid out as MoonScript's, so Howlscript and MoonScript classes can
extend each other:

- **Class object:** holds `__init`, `__base`, `__name` and `__parent`. Its metatable
  looks names up in the base and then the parent, and calling it creates an instance.
- **Instances:** an instance's metatable is the class's `__base`. The base has
  `__index` set to itself and `__class` pointing at the class, and it inherits from
  the parent's base through its metatable.

Properties and fallbacks extend this:

- **Dispatching classes:** a class with properties or fallbacks, or with a parent
  that has them, keeps its properties in its base's `__properties`.
  - That's a table of `{get = f, set = f}` tables by name, including the inherited
    ones.
  - Its base's `__index` and `__newindex` are functions, which try the properties,
    the methods (along the bases), the fallbacks and the instance, in that order.
  - The fallbacks are kept in the base as `__hs_index` and `__hs_newindex`.
- **Inheritance:** metamethods and fallbacks are copied to the base of a subclass
  when it's created, and its properties are set up then.
- **MoonScript subclasses:** they get the same setup through the parent's
  `__inherited`. Classes with metamethods, properties or fallbacks wrap their
  `__inherited` to do that, and still call the one they had.
- **PropertyObject:** a class extending a MoonScript class built on Howl's
  `PropertyObject` uses `@property` and `@meta` instead. PropertyObject replaces the
  base's `__index` and `__newindex` with its own.

A class without a parent, properties, fallbacks or metamethods compiles to exactly
MoonScript's layout.

## Compared with MoonScript

This compares Howlscript with MoonScript 0.5.0, the version in `lib/ext/moonscript`.

### Changed

| MoonScript | Howlscript |
|---|---|
| `obj\method args` | `obj:method(args)`. Using `\` is an error. |
| `f!` | `f()`. `!` is an error; negate with `not`. |
| `print sum 10, 20`, `x = f a` | `print sum(10, 20)`, `x = f(a)`. Only a call that is a statement of its own can leave out its parentheses, and only one per line (see [Calls without parentheses](#calls-without-parentheses)). A call whose only argument is a table needs none anywhere, as in Lua. |
| `f (a)` passes `(a)` | An error: the `(` must touch the function. `f (x) -> x` still passes a function. |
| `x -1` calls `x(-1)` | A subtraction. |
| Arguments continued on indented lines, nested by indentation | Inside parentheses, where line breaks are free. Without parentheses, arguments only continue after a trailing `,` and can't nest. |
| `f a: 1, 2` | An error: positional arguments come first. |
| `x = a: 1`, `return a: 1`, indented key blocks | `x = {a: 1}`. A table needs braces, except for the trailing named arguments of a call. |
| `@property name: get: => @x`, with Howl's `PropertyObject` | `property name => @x` (see [Properties](#properties)). In a class still extending `PropertyObject`, `@property(name: {get: => @x})`, as a nested table needs its braces. |
| `@meta __tostring: => @x`, with Howl's `PropertyObject` | `__tostring: => @x`, a member (see [Metamethods](#metamethods)). |
| A subclass doesn't inherit its parent's metamethods | It does. |
| An `__index` member is ignored, as the base's `__index` is set to the base afterwards | `__index:` and `__newindex:` are fallbacks for keys the instance doesn't have (see [Metamethods](#metamethods)). |
| `f[[text]]` calls `f` | An error: write `f([[text]])`, or `f [[text]]` in a statement. |
| `x = f {a}, b` passes `{a}` and `b` to `f` | Passes only the table, as in Lua: `x = f({a}), b`. Only at the start of a statement does `f {a}, b` pass both. |
| `x--note` is a comment | A decrement followed by `note`. Write `x -- note`. |
| `unless a ... elseif b` | `unless` takes an `else` but no `elseif`. |
| `if`, `unless` and `switch` are values: `label = if n == 1 then 'item' else 'items'`, `return if c then a else b` | Statements without a value, so using one as a value is an error. Assign or return in the branches. |
| A function ending in an `if`, `unless`, `switch` or `do` returns the value its body ends with | It returns only what the body returns with `return`; a value or a call ending a branch is an error. A statement modifier at the end, as in `-> f(x) if x`, still passes on its value. |
| Loops are values: `doubled = for x in *t` collects a list | Statements without a value; collect with a comprehension. |
| Comprehensions and `for` modifiers filter with `when`: `[x for x in *t when x > 0]` | With `if` or `unless`: `[x for x in *t if x > 0]`. `when` there is an error; it only starts the cases of a `switch`. |
| A comprehension takes several `for` and `when` clauses: `[{x, y} for x in *xs for y in *ys]` | A single `for`, with at most one filter. Nest `for` loops instead, and combine conditions with `and`. |
| `x = do ...` gives the value of the block's last statement | An error: a `do` block is a statement. |
| `(@x = 5, y = @x) =>` runs all defaults before setting `self.x`, so `y` gets the old `self.x` | Handles the parameters in order, so `y` gets 5. |
| Parameters and loop variables can shadow locals | An error; rename one of them (see [Scope](#scope)). |
| A class body adds all its members before running its other statements | It runs top to bottom (see [Classes](#classes)). |
| `goto` can be a variable name | An error, like the other Lua keywords Howlscript doesn't use. |
| `import`, `from`, `using` and `extends` are reserved | They're ordinary names; `extends` only means something after a class name. |
These MoonScript 0.5.0 bugs are fixed:

- **Update operators:** `t[f()] += 1` and `f().n += 1` call `f` twice. Howlscript
  calls it once.
- **Destructuring among other targets:** in `a, {:b}, c = f()`, `b` and `c` get nil.
  In Howlscript, `b` is read from `f`'s second value, and `c` is its third value.
- **Lua keywords as method names:** `obj\end!` and `@end` compile to invalid Lua.

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
| `(@@x) =>`, setting `self.__class.x` | `@@x = x` in the body. |
| `export ^` | `export A, B`, naming each. |
| `x = class ...`, `class extends Base` (class expressions and anonymous classes) | A named class statement, then `x = Name`. |
| `class a.B` | `class B`, then `a.B = B`. |
| `if x = f()`, `elseif x = f()` | `x = f()` before the `if`. For `elseif`, nest an `if` in the `else`. |
| `with x = f()` | `x = f()`, then `with x`. |
| `&`, `\|`, `~`, `<<`, `>>`, `//` and `&=`, `\|=`, `<<=`, `>>=` | The `bit` library, as in `bit.band(a, b)`, and `math.floor(a / b)`. MoonScript compiles them to Lua 5.3 operators, which LuaJIT doesn't have. |
| `[==[long]==]` | `[[long]]`, or a quoted string when the text contains `]]`. |

### New

- **`++` and `--`:** `x++` and `t.count--` add or subtract 1. They're statements, so
  `y = x++` is an error.
- **`local a = value`:** declares and assigns. MoonScript's `local` only declares, and
  `local a = 1` doesn't parse.
- **Destructured parameters:** a parameter can be a pattern that takes its argument
  apart, as in `area = ({:width, :height}) -> width * height` (see
  [Destructured parameters](#destructured-parameters)). MoonScript 0.5.0 has no such
  parameters. It reads `({:width, :height})` as a table in parentheses, called with the
  function `-> width * height`, so the line fails when it runs instead of defining a
  function:

  ```lua
  local area = ({width = width, height = height})(function()
    return width * height
  end)
  ```
- **Properties:** `property name => @x`, or with a block of `get:` and `set:`, in a
  class body (see [Properties](#properties)).
- **Numbers:** all of LuaJIT's forms, where MoonScript 0.5.0 lacks `0XFF`, `1e+2`,
  hex floats such as `0x1p4`, and imaginary numbers such as `2i`.
- **Hints:** errors for MoonScript habits like `\`, `!`, `f (x)`, braceless tables,
  `using` and stubs say what to write instead.
