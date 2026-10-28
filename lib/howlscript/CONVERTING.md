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
  `_G.with_tmpdir = (f) -> ...`.
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

- **`with` lines:** `\m args` becomes `:m(args)`, as `\indent!` becomes `:indent()`.

### Tables

A table without braces gets them:

- `return :a, :b` becomes `return {:a, :b}`, and `x = a: 1` becomes `x = {a: 1}`.
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

### Control flow

- `else if c then x` becomes `elseif c then x`.
- A `when` filter in a comprehension or `for` modifier becomes `if`.
- **`if` as a value:** the names are declared before the `if`, and each branch
  assigns them:

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

### Classes

A class extending `PropertyObject` loses its parent, and with it the `super!` in
`new`:

- `@property x: get: => e` becomes `property x => e`.
- `@meta {...}` entries become members, as in `__tostring: => ...`.
- Writing a read-only property now fails with `property 'x' is read-only`.

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
