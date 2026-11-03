# Converting MoonScript to Howlscript

How Howl's MoonScript is converted to Howlscript, collected from modules converted by
hand. The converter will follow these rules, and the hand-converted modules will check
it. [REFERENCE.md](REFERENCE.md) lists every difference between the two languages;
this says what a converted file should look like.

## Principles

- **Mechanical:** a conversion changes only what Howlscript requires, so it reads
  line by line against the original. Improvements, like `x = x or {}` to `x or= {}`,
  are separate changes.
- **In place:** the `.howl` file replaces the `.moon` file of the same name, which
  `require` and `bundle_load` then find instead.
- **Copyright:** a copyright line's years end with the year of the conversion, so
  `2012-2015` becomes `2012-2026`, and `2018` becomes `2018-2026`. That includes a
  bundle's `info.author` when it holds the copyright. A file without the usual
  two-line header gets one, starting from the year its original was added
  (`git log --follow --diff-filter=A`). A bundle's `misc/` examples get none, like
  most of the others there.

## Rules

### Imports

`import a, b from t` becomes `{:a, :b} = t`.

### Globals

Howlscript has no `export`, so assigning to a name always declares a local unless one
is visible:

- **Real globals** are set through `_G`: `export with_tmpdir = (f) -> ...` becomes
  `_G.with_tmpdir = (f) -> ...`. A run of them goes in a `with _G` block, as for a
  module table below. A name that `export *` made global only because it was in its
  scope, and that nothing else uses, becomes a local instead, as `globals.moon`'s
  `_orig_coro_create` and `_tracked_coroutines` did.
- **Writing a global through the function's environment,** as code run in a
  `Sandbox` does, can't be written in Howlscript, since `_G.x` bypasses the
  environment. Code that needs it is Lua, as `sandbox_spec` loads it with
  `loadstring("frob = 'bar!'")`. Bundles and user init files run with
  `no_implicit_globals`, so they never need it.
- **A module that `setfenv`s to its own table and exports into it** drops the
  `setfenv`, and every exported name becomes a field of the table wherever it's
  defined, read or written, also in nested functions and when the module calls its
  own functions. A run of definitions goes in a `with` block on the table, where
  `.name` reaches the fields in nested functions too. A table called `_ENV` gets the
  module's name:

  ```moonscript
  _ENV = {}
  setfenv 1, _ENV
  export delete, change
  export reset = ->
    delete = false
  export execute = (f) ->
    reset!
  return _ENV
  ```

  ```howl
  state = {}
  with state
    .reset = ->
      .delete = false
    .execute = (f) ->
      .reset()
  return state
  ```

  Inside another `with` in such a block, `.name` is the inner target's, so the
  module's fields are written out there (`state.delete`). A local with the table's
  name, like the `state` in `vi/state`'s `apply`, would update the table instead of
  declaring a local, so it gets renamed.

  A `setfenv` that gives other code an environment stays, as `lpeg_lexer`'s does for
  lexer definitions.

### Calls

- `obj\m args` becomes `obj:m(args)`, and `f!` becomes `f()`.
- **Parentheses:** every call gets them, in specs too, except:
  - a call taking a function block;
  - a call whose only argument is a table;
  - in specs, statements calling busted's `describe`, `context`, `it`,
    `before_each`, `after_each`, `setup`, `teardown` and `pending`, and assertions
    (`assert.equal 'x', buffer.text`). A spec's own helpers get parentheses, as in
    `assert_lines({...}, m:structure(editor))`.

  ```moonscript
  table.insert clips, 1, item
  error "Unknown signal '#{name}'", 2 unless all[name]
  system_clipboard\read_text_async (res) ->
    ...
  config.define {
    name: 'clipboard_max_items'
  }
  ```

  ```howl
  table.insert(clips, 1, item)
  error("Unknown signal '#{name}'", 2) unless all[name]
  system_clipboard:read_text_async (res) ->
    ...
  config.define {
    name: 'clipboard_max_items'
  }
  ```

- **Calls in other calls' arguments and calls used as values** get parentheses
  everywhere, also in the arguments of a spec call and in inline functions there, in
  block headers and in interpolations:

  ```moonscript
  assert.raises 'none', -> signal.connect 'none', -> true
  for handler in *handlers_for name
  co = coroutine.create (...) -> handler ...
  if first\match '%p'
  "Context<#{tostring @buffer}>"
  ```

  ```howl
  assert.raises 'none', -> signal.connect('none', -> true)
  for handler in *handlers_for(name)
  co = coroutine.create((...) -> handler(...))
  if first:match('%p')
  "Context<#{tostring(@buffer)}>"
  ```

- **A function block in arguments:** when a call with a function block is itself an
  argument, the parentheses close on a line of their own after the block:

  ```moonscript
  system_cb\read_text_async async (res) ->
    assert.equals 'global!', system_cb\read_text_finish(res)
    done!
  ```

  ```howl
  system_cb:read_text_async(async((res) ->
    assert.equals 'global!', system_cb:read_text_finish(res)
    done()
  ))
  ```

- **A table as the only argument:** the call keeps its form anywhere, since
  Howlscript takes a table after a name as its only argument, as Lua does. Other
  arguments, a long string included, get parentheses as usual:

  ```moonscript
  primary = PropertyTable {
    clear: -> system_primary\set_text ''
  }
  keyword = c 'keyword', word {
    'auto', 'break'
  }
  buffer.text = trimmed_text [[
    int main() {}
  ]]
  ```

  ```howl
  primary = PropertyTable {
    clear: -> system_primary:set_text('')
  }
  keyword = c('keyword', word {
    'auto', 'break'
  })
  buffer.text = trimmed_text([[
    int main() {}
  ]])
  ```

- **A module ending in a call** gets `return` and parentheses, so its value stands
  out: `PropertyTable Clipboard` becomes `return PropertyTable(Clipboard)`. A call
  taking a function block keeps its form, as lexers' `howl.util.lpeg_lexer ->` does.

- **A comprehension as the first argument:** the call gets parentheses, since
  `f [x]` reads as an index: `assert.same [a for a in *t], b` becomes
  `assert.same([a for a in *t], b)`.
- **Named arguments before positional ones** get braces:
  `assert.same description: 'bar', x` becomes `assert.same {description: 'bar'}, x`.
- **Function stubs:** `obj\m` becomes `(...) -> obj:m(...)`, so `pcall obj\m, res`
  becomes `pcall((...) -> obj:m(...), res)`.
- **Several values after an inline function** in arguments or a table: MoonScript
  takes them into its body, where a `,` ends the body in Howlscript. So the function
  gets parentheses: `spy.new -> 'r1', 'r2'` becomes `spy.new((-> 'r1', 'r2'))`. Howl
  has 9 such places, one of them a mistake: in `spec/project_spec.moon`,
  `paths: -> {}, files: -> {}` puts `files` in the body of `paths`.
- **Arguments on the lines after a call:** they're named, so they become a table,
  with its own braces. When they're the only arguments, the call takes just that
  table. After a positional argument, the table opens on the call's line and closes
  with `})`. Named arguments on the call's own line stay as they are, as in
  `Clipboard.push(text, no_sync: true)`.

  ```moonscript
  config.define
    name: 'max_log_entries'
    default: 1000

  signal.register 'log-trimmed',
    description: 'Signaled right after the log is trimmed'
    parameters:
      size: 'The new number of entries in the log'
  ```

  ```howl
  config.define {
    name: 'max_log_entries'
    default: 1000
  }

  signal.register('log-trimmed', {
    description: 'Signaled right after the log is trimmed'
    parameters: {
      size: 'The new number of entries in the log'
    }
  })
  ```

- **Positional arguments continued after a trailing `,`** keep their lines inside
  the parentheses, which close after the last one:

  ```moonscript
  t_handle.tag = C.g_idle_add_full C.G_PRIORITY_LOW,
    timer_callback,
    nil
  ```

  ```howl
  t_handle.tag = C.g_idle_add_full(C.G_PRIORITY_LOW,
    timer_callback,
    nil)
  ```

- **`with` lines:** `\m args` becomes `:m(args)`, as `\indent!` becomes `:indent()`.

### Tables

A table without braces gets them:

- `return :a, :b` becomes `return {:a, :b}`, and `x = a: 1` becomes `x = {a: 1}`.
- **A table ending a function, below other statements,** gets braces with its
  entries on lines of their own, as `complete: -> completions` did in
  `completion_popup_spec`:

  ```howl
  (_, _, on_update) ->
    notify = on_update
    {
      complete: -> completions
    }
  ```
- **A table nested under a key** gets braces with its entries on lines of their
  own, whether it was an indented block or on the key's line. So does the table
  around it: `app.window = visible: true, status: [m]: method` becomes a table over
  four lines, holding one over three. Here is how nested tables look in a table
  that's already over several lines:

  ```moonscript
  text:
    set: (v) => ...
    get: => ...
  current: get: ->
    clips[1]
  clips: get: -> clips
  ```

  ```howl
  text: {
    set: (v) => ...
    get: => ...
  }
  current: {
    get: ->
      clips[1]
  }
  clips: {
    get: -> clips
  }
  ```

### Layout

A line continuing an expression is indented deeper than the line it continues, as
Howlscript requires, so a continuation at the same indentation moves in:

```moonscript
opening_decl_p\test(l) or
opening_decl_comma_p\test(l)
```

```howl
opening_decl_p:test(l) or
  opening_decl_comma_p:test(l)
```

A body after `then`, `do` or `else` on the same line, as in `if c then x = 1 else
x = 2` or `when 'nil' then append(out, 'null')`, moves to lines of its own. The
language allows it, but the user prefers the block. Statement modifiers (`x = 1 if c`)
stay as they are.

```moonscript
if not index or index > #list + 1 then index = #list + 1
elseif index < 1 then index = 1
```

```howl
if not index or index > #list + 1
  index = #list + 1
elseif index < 1
  index = 1
```

### Control flow

- `else if c then x` becomes `elseif c then x`.
- A `when` filter in a comprehension or `for` modifier becomes `if`.
- **`if` as a value:** the names are declared before the `if`, and each branch
  assigns them. A field needs no declaration, and a branch already ending in an
  assignment keeps it, as MoonScript drops the outer one there (`Chunk`'s
  `styles`):

  ```moonscript
  pfx_p, sfx_p = if first\match '%p'
    '%p+$', '^%p+'
  elseif first\match '%w'
    '%w+$', '^%w+'
  ```

  ```howl
  local pfx_p, sfx_p
  if first:match('%p')
    pfx_p, sfx_p = '%p+$', '^%p+'
  elseif first:match('%w')
    pfx_p, sfx_p = '%w+$', '^%w+'
  ```

  An `if` value on one line becomes an `if` statement over several lines too (see
  [Layout](#layout)):

  ```moonscript
  env = if options.env then moon.copy options.env else {}
  ```

  ```howl
  local env
  if options.env
    env = moon.copy(options.env)
  else
    env = {}
  ```

- **A loop as a value** collects into a new local list, which is then returned or
  assigned, unless a comprehension can do it. The list's name mustn't be a visible
  local, as `vc`'s `files` function ruled out `files`:

  ```moonscript
  return for i = 1, #paths
    path = paths[i]
    File groot\get_child(path)
  ```

  ```howl
  result = {}
  for i = 1, #paths
    path = paths[i]
    result[#result + 1] = File(groot:get_child(path))
  return result
  ```

- **A one-line function ending in a `for` modifier, inside a table or call
  arguments,** gets a block body, as the user prefers:
  `put: (t) => rawset env, k, v for k,v in pairs t` becomes `put: (t) =>` with
  `rawset(env, k, v) for k,v in pairs(t)` on the next line. The one-line form
  compiles in keyed entries and call arguments, but not in `[ ]` or a table's
  positional entries, where it would be unclear.

- **A function ending in an `if`, `unless` or `switch`:** where one of its bodies
  ends in a value, a call or a `with` block, MoonScript returned that, so it gets a
  `return`, also in nested `if`s:

  ```moonscript
  after = (seconds, f, ...) ->
    if seconds != 0
      after_approximately seconds, f, ...
    else
      after_exactly seconds, f, ...
  ```

  ```howl
  after = (seconds, f, ...) ->
    if seconds != 0
      return after_approximately(seconds, f, ...)
    else
      return after_exactly(seconds, f, ...)
  ```

  A `with` block becomes `return with x`, as in `vi/state`'s `apply`.

### Parameters

Howlscript has no `@x` parameters. Each becomes a plain parameter, assigned to its
field at the top of the body, one line each, in the order of the parameters:

```moonscript
new: (@buffer, @pos) =>
show: (widget, @show_options = {position: 'center'}) =>
  error('Missing argument #1: widget', 2) if not widget
```

```howl
new: (buffer, pos) =>
  @buffer = buffer
  @pos = pos
show: (widget, show_options = {position: 'center'}) =>
  @show_options = show_options
  error('Missing argument #1: widget', 2) if not widget
```

### Names

- **Shadowing:** a parameter or loop variable that shadows a visible local gets
  another name, as `op = (editor) -> ...` inside a function with an `editor`
  parameter became `op = (ed) -> ...`. A parameter named `self`, as in a keymap's
  `on_unhandled: (event, source, translations, self) ->`, keeps its name, as `self`
  is exempt.
- **A local named like the module table** in a module that used `setfenv`, as with
  `state` in `vi/state`'s `apply`, gets a name for what it holds (`snapshot`).

### Classes

Howlscript code never uses `PropertyObject`, as its classes have properties of their
own. A class extending it loses its parent, and with it the `super!` in `new`. A
hierarchy built on it converts as a unit, its root with all its subclasses, so that no
Howlscript class extends a `PropertyObject` class and no MoonScript class needs
`@property` from a Howlscript parent, as the `Popup` chain did:

- `@property x: get: => e` becomes `property x => e`.
- A property with `get:` and `set:` becomes a `property x` block holding them:

  ```moonscript
  @property text:
    get: => @_text
    set: (text) => @buffer\replace text
  ```

  ```howl
  property text
    get: => @_text
    set: (text) => @buffer:replace(text)
  ```

- `@meta {...}` entries become members, as in `__tostring: => ...`.
- Writing a read-only property now fails with `property 'x' is read-only`.
- A class or module with a Howlscript port in `lib/howlscript/spec/fixtures/` drops
  the port and its line in `acceptance_spec.moon`, as its own spec now runs against
  the real thing.

## Converted by hand

| Original | Converted |
|---|---|
| `lib/howl/signal.moon`, `spec/signal_spec.moon` | 2026-10-26 |
| `lib/howl/buffer_context.moon`, `spec/buffer_context_spec.moon` | 2026-10-26 |
| `lib/howl/clipboard.moon`, `spec/clipboard_spec.moon` | 2026-10-26 |
| `bundles/c/` (`init`, `c_mode`, `c_lexer`, `spec/c_mode_spec`) | 2026-10-26 |
| `lib/howl/log.moon`, `spec/log_spec.moon` | 2026-10-28 |
| `lib/howl/editing/formatting.moon`, `spec/editing/formatting_spec.moon` | 2026-10-28 |
| `lib/howl/util/dotenv.moon`, `spec/util/dotenv_spec.moon` | 2026-10-28 |
| `lib/howl/globals.moon`, `spec/globals_spec.moon` | 2026-10-28 |
| `lib/howl/timer.moon`, `spec/timer_spec.moon` | 2026-10-28 |
| `bundles/vi/state.moon` | 2026-10-28 |
| `lib/howl/chunk.moon`, `spec/chunk_spec.moon` | 2026-10-30 |
| `lib/howl/util/json.moon`, `spec/util/json_spec.moon` | 2026-10-30 |
| `lib/howl/io/input_stream.moon`, `spec/io/input_stream_spec.moon` | 2026-10-30 |
| The `Popup` chain: `lib/howl/ui/` `popup`, `buffer_popup`, `menu_popup` and `completion_popup`, with their specs | 2026-11-02 |
| `lib/howl/util/sandbox.moon`, `spec/util/sandbox_spec.moon` | 2026-11-02 |
| `lib/howl/vc.moon`, `spec/vc_spec.moon` | 2026-11-02 |
| `bundles/ruby/ruby_inspector.moon` | 2026-11-02 |
