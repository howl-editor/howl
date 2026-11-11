# Converting MoonScript to Howlscript

How Howl's MoonScript is converted to Howlscript, collected from modules converted by
hand. [REFERENCE.md](REFERENCE.md) lists every difference between the two languages;
this says what a converted file should look like.

The converter, `convert.lua` here, follows these rules, and `bin/howl-convert` runs
it (`-w --howl` writes Howl's own files in place). It reproduces the hand-converted
modules, apart from their fixes made by hand. What it can't decide is left as it is,
for the Howlscript compiler to reject or with a warning, and fixed by hand following
the rules below (see [By hand](#by-hand)).

## Principles

- **Mechanical:** a conversion changes only what Howlscript requires, so it reads
  line by line against the original. Improvements, like `x = x or {}` to `x or= {}`,
  are separate changes.
- **Odd spacing is fixed,** as two spaces where one belongs (`new:  =>`, `->  x`,
  `x  = 1`), a space before a comma or none after it, a block indented by other
  than two spaces, a closing brace on a line of its own not lined up with the line
  its table opens on, trailing whitespace, or `for _=1,n` for `for _ = 1, n`.
  Spacing inside strings stays, and so do the lines of a long string in a block
  that moves.
- **Bugs found on the way** are fixed in the conversion and named in its commit, as
  `window_spec`'s `assert.is_nil, win.current_view` was: a value list, not a call,
  so it asserted nothing.
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

- **A function block in arguments or a `return`:** when a call with a function block
  is itself an argument, or gets a `return` (see [Control flow](#control-flow)), the
  parentheses close on a line of their own after the block, as with `bundle`'s
  `return lookup.loader(->`:

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
- **A space before parentheses:** MoonScript's `f (a)` passes `(a)`, while Howlscript
  rejects the space. When the parentheses hold all the arguments, the space goes:
  `DirectoryExplorer (tmp_root .. 'sub/')` becomes
  `DirectoryExplorer(tmp_root .. 'sub/')`. Around a call or `...` they stay, as they
  cut its values down to one: `f (g!)` becomes `f((g()))`. Otherwise the call gets
  parentheses of its own around them, and an assertion gets them too, since its
  argument can't start a call without them:

  ```moonscript
  DirectoryExplorer (@file / selection.path), @_copy_opts!
  assert.is_nil ([b for b in *app.buffers when b.file == other])[1]
  ```

  ```howl
  DirectoryExplorer((@file / selection.path), @_copy_opts())
  assert.is_nil(([b for b in *app.buffers if b.file == other])[1])
  ```

- **A negative first argument:** MoonScript's `f -1`, with a space before the `-`
  and none after it, calls `f(-1)`, where Howlscript subtracts. The call gets its
  parentheses as usual, so `s\usub -2` becomes `s:usub(-2)`. An assertion starting
  with one gets them too, since its argument can't start a call without them:
  `assert.equals -1, x` becomes `assert.equals(-1, x)`.

- **Named arguments before positional ones** get braces:
  `assert.same description: 'bar', x` becomes `assert.same {description: 'bar'}, x`.
- **Function stubs:** `obj\m` becomes `(...) -> obj:m(...)`, so `pcall obj\m, res`
  becomes `pcall((...) -> obj:m(...), res)`. A stub on self keeps its spelling:
  `@\m` becomes `(...) -> @m(...)`, as in `Selection`'s listener, and `self\m`
  becomes `(...) -> self:m(...)`, as in `Buffer`'s.
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

  MoonScript also takes such a table after an argument without a comma. After a
  string, as in `interact.search`'s calls, the comma is added:
  `f 'a'` with `b: 1` below becomes `f('a', {`. After a name, MoonScript calls the
  name with the table, which stays so: `f a` with `b: 1` below becomes `f(a {`.

- **A table as the only argument of a call on anything but a name,** as an index,
  gets parentheses, as Howlscript only takes a table after a name as an argument:
  `callbacks[1]` with `a: 1` below becomes `callbacks[1]({`.

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
- **A key touching its value,** as in `sort:not x` or `text:remaining_text`, gets a
  space after the `:`, since Howlscript reads `a:b` as a method call.
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
language allows it, but the user prefers the block. So does a body that MoonScript
takes without `then`, as in `preview: => if c return {`. A `then` ending the line
before its block stays, as in `File`'s `if File.async then`, and so do statement
modifiers (`x = 1 if c`).

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

A comment touching a name or `]` gets a space, as Howlscript reads the `--` as a
decrement there: `x--note` becomes `x --note`. Comment lines ending a block stay in it,
above the closing brackets added after it.

### Strings

A long string with a level becomes one without, `[==[text]==]` becoming
`[[text]]`, or a single-quoted string when its text contains `]]`, as
`[==[a]]b]==]` becomes `'a]]b'`.

### Control flow

- `else if c then x` becomes `elseif c then x`.
- A `when` filter in a comprehension or `for` modifier becomes `if`.
- **A simple `if` value becomes `and` and `or`** (decided 2026-11-11), wherever its
  value is used: assigned, returned, ending a function, or inside an expression,
  where it gets parentheses as an operand. That's an `if` or `unless` with an
  `else` and no `elseif`, each branch a single expression on one line, whose `then`
  value can't be false or nil, being a string, number, table or function literal,
  arithmetic or `true`. The `c and a or b` it becomes must fit in 100 columns, and
  the `if` must hold no comments. A condition with an `or` outside parentheses gets
  them, as does an `unless` condition after its `not`:

  ```moonscript
  text: if l.nr == last_lnr then '·' else tostring l.nr
  x = if not a or b then 'y' else z
  ```

  ```howl
  text: l.nr == last_lnr and '·' or tostring(l.nr)
  x = (not a or b) and 'y' or z
  ```

  Any other `if` value becomes an `if` statement, as below.

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

  An `if` value without `else` is `nil` when nothing matches, so the `if` statement
  gets an `else` assigning `nil`, unless the name is surely `nil` there already, as
  the just declared `left` in `Window`'s `siblings` is:

  ```moonscript
  left = if before and before.y == current.y then before
  ```

  ```howl
  if before and before.y == current.y
    left = before
  ```

  Any other `if` value inside an expression, as a table entry, an argument or a list
  element, goes into a local declared just before the statement and assigned in each
  branch, and the expression uses the local. It's named after the key it fills, as
  `:text` in `HelpContext`'s `add_section`, or the parameter it's passed for, unless
  that's a visible local, as `text` was in `ExplorerView`'s `refresh`:

  ```moonscript
  @explorer_view\redraw_text if text.is_empty then current_value else text
  @explorer_view\redraw_prompt if @item.display_path then @item\display_path! else nil
  ```

  ```howl
  local new_text
  if text.is_empty
    new_text = current_value
  else
    new_text = text
  @explorer_view:redraw_text(new_text)
  local prompt
  if @item.display_path
    prompt = @item:display_path()
  else
    prompt = nil
  @explorer_view:redraw_prompt(prompt)
  ```

  A returned `if` value becomes an `if` statement returning in each branch, as in
  `ustring`'s `byte_offset`:

  ```moonscript
  return if is_table
    offsets
  else
    table.unpack offsets
  ```

  ```howl
  if is_table
    return offsets
  else
    return table.unpack(offsets)
  ```

- **`switch` as a value** becomes a statement assigning in each case, as `if` does,
  with its `when … then` bodies on lines of their own:

  ```moonscript
  absolute_path = switch @file.path
    when File.separator then @file.path .. text
    else @file.path .. File.separator .. text
  ```

  ```howl
  local absolute_path
  switch @file.path
    when File.separator
      absolute_path = @file.path .. text
    else
      absolute_path = @file.path .. File.separator .. text
  ```

- **A loop as a value** collects into a new local list, which is then returned or
  assigned, unless a comprehension can do it. A loop assigned to a new name collects
  straight into it, as `items = for i = 1, #paths` in `DirectoryExplorer` did, but
  one assigned to the list it goes over collects into a new one, as `byte_matches`
  for `matches` in `Buffer`'s `replace`. The list's name mustn't be a visible local,
  as `vc`'s `files` function ruled out `files`:

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

- **A comprehension with two `for`s** becomes nested loops collecting into a new
  local list, as a loop as a value does. Used as an argument, it's collected before
  the statement, as in `lsp/rename`:

  ```moonscript
  locations = to_locations [{ uri: d.uri, range: e.range } for d in *docs for e in *d.edits], state.client.root
  ```

  ```howl
  lsp_locations = {}
  for d in *docs
    for e in *d.edits
      lsp_locations[#lsp_locations + 1] = { uri: d.uri, range: e.range }
  locations = to_locations(lsp_locations, state.client.root)
  ```

- **An expression kept for its effect,** which Howlscript rejects as a statement that
  does nothing: a conditional call `a and f(...)` becomes `f(...) if a`, as in
  `TextWidget`'s listener, and a read that triggers a lazy computation is assigned to
  `_`, as `d_line.block` became `_ = d_line.block` in aullar's `display_lines` spec.
  Ending a function, such an expression is its value, and stays. Other expressions
  that do nothing are mistakes, fixed as bugs found on the way.

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

  Setters and constructors are the exception. Nothing uses their values, as a
  property assignment throws the setter's away, as PropertyObject's did, so
  Howlscript compiles them without one, and their `if`s stay as they are, as in
  `Buffer`'s `modified` setter.

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
`@property` from a Howlscript parent, as the `Popup` and `Buffer` chains did:

- `@property x: get: => e` becomes `get x: => e`, and a set-only
  `@property x: set: (v) => ...` becomes `set x: (v) => ...`.
- A property with `get:` and `set:` becomes a `get` and a `set`, the getter first. A
  blank line between them stays, as in `Window`'s `fullscreen`, and they stay
  together without one, as in `BufferPopup`'s `buffer`:

  ```moonscript
  @property text:
    get: => @_text
    set: (text) => @buffer\replace text
  ```

  ```howl
  get text: => @_text
  set text: (text) => @buffer:replace(text)
  ```

- **Overrides:** a subclass's `@property` replaced both of its parent's accessors,
  while a `get` or `set` replaces only its own and keeps the parent's other one. Howl's
  one override, `ActionBuffer`'s `modified`, gives both, so it converted as is, to
  `get modified: -> false` and `set modified: ->`.

- **Metamethods** go in the class's `meta`, whether they were members or given to
  `@meta {...}`. Subclasses inherit them in Howlscript, where a MoonScript subclass
  didn't inherit metamethod members, but no Howl class meets that: the one plain class
  with metamethod members, `Matcher`, has no subclasses, and PropertyObject's `@meta`
  already reached subclasses, as `Buffer`'s did. It stands where the first of them stood, with its braces on lines of
  their own and an entry on each line:

  ```moonscript
  __tostring: => @text
  __len: => (@end_pos - @start_pos) + 1
  ```

  ```howl
  meta {
    __tostring: => @text
    __len: => (@end_pos - @start_pos) + 1
  }
  ```

- **Delegation:** a class passing `super target` to `PropertyObject`, so that the
  keys it lacks go to `target`, gets an `__index` fallback in its `meta` instead. It
  reads the target with `rawget`, since reading `@win` before `new` sets it would run
  the fallback again, and calls methods on the target. PropertyObject kept one
  target per class, the last instance's, so every `Window` delegated to the newest
  Gtk window; the fallback's is the instance's own:

  ```moonscript
  class Window extends PropertyObject
    new: =>
      @win = Gtk.Window!
      super @win
  ```

  ```howl
  class Window
    new: =>
      @win = Gtk.Window()

    meta {
      __index: (key) =>
        win = rawget(self, 'win')
        return nil unless win
        value = win[key]
        return value unless callable(value)
        (_, ...) -> value(win, ...)
    }
  ```

- **An `__index` member** did nothing in MoonScript, as the base's `__index` replaced
  it, while in `meta` it's a fallback. The converter moves it there with a warning,
  to be dropped or kept by hand.
- **Members reading class-body locals:** MoonScript added a class's members before
  running its body, so a member reading a local the body assigns saw nil, where
  Howlscript, running the body top to bottom, sees the value assigned above it. The
  converter warns about such members. Howl has none.
- **`super` outside classes:** `super` only works in derived classes, while Howl's
  modes called the parent mode's version of a method with a `super` that
  `mode.moon` put in their environment. A mode's `create` now gets the parent mode
  as its second argument, and the mode calls through that, as
  `parent.indent_for(@, line, indent_level)`. Unlike `@parent`, which is the parent
  of the mode a method is called on, it's the defining mode's parent, also when a
  sub-mode inherits the method. `ruby_mode` and `coffeescript_mode` were changed so
  before their conversion, and `mode.moon` no longer gives modes a `super`.
- **Errors:** writing a read-only property fails with `property 'x' is read-only`,
  where PropertyObject's message was `Attempt to set read-only property "x"`. Reading
  a set-only one fails with `property 'x' is write-only`, where PropertyObject went
  on to the methods and returned nil. Howl's two set-only properties are never read.
- **A module ending in a class** stays as it is, as Howlscript returns a class ending
  a file, like MoonScript, so `directory_explorer` still returns `DirectoryExplorer`.
- **Members added to `__base` after the class** stay as they are, as instances find
  them, also in a class with properties: `File.__base.rm = File.delete` gives every
  file `rm`.
- **PropertyObject** itself was removed once its last classes were converted, with
  its spec and the compiler's specs for classes built on it. Classes extending it
  convert as above.

## By hand

The converter leaves these as they are, for the rules above to be applied by hand.
The Howlscript compiler rejects all but the warned ones, and `bin/howl-convert`
reports both:

- `export`, and `setfenv` modules (see [Globals](#globals));
- loops as values, warned about, and comprehensions with two `for`s;
- `if` values inside expressions not simple enough for `and` and `or`, and `switch`
  values inside expressions;
- expressions kept for their effect;
- parameters and loop variables shadowing a local;
- assignments in `if` and `with` headers.

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
| `lib/howl/ui/window.moon`, `spec/ui/window_spec.moon` | 2026-11-10 |
| `lib/howl/bundle.moon`, `spec/bundle_spec.moon` | 2026-11-10 |
| `lib/howl/lsp/rename.moon`, `spec/lsp/rename_spec.moon` | 2026-11-10 |
| `lib/howl/ui/selection.moon`, `spec/ui/selection_spec.moon` | 2026-11-10 |
| `lib/howl/explorers/directory_explorer.moon`, `spec/explorers/directory_explorer_spec.moon` | 2026-11-10 |
| `lib/howl/ustring.moon`, `spec/ustring_spec.moon` | 2026-11-11 |
| `lib/howl/io/file.moon`, `spec/io/file_spec.moon` | 2026-11-11 |
| `lib/howl/buffer_markers.moon`, `spec/buffer_markers_spec.moon` | 2026-11-11 |
| The `Buffer` chain: `lib/howl/buffer`, and in `lib/howl/ui/` `action_buffer`, `list_buffer`, `process_buffer`, `process_list_buffer` and `journal_buffer`, with the specs of `buffer`, `action_buffer` and `process_list_buffer` | 2026-11-11 |
| `lib/howl/ui/help_context.moon`, `spec/ui/help_context_spec.moon` | 2026-11-11 |
| `lib/howl/ui/explorer_view.moon`, `spec/ui/explorer_view_spec.moon` | 2026-11-11 |
| `lib/howl/ui/text_widget.moon`, `spec/ui/text_widget_spec.moon` | 2026-11-11 |
| `lib/aullar/spec/display_lines_spec.moon` | 2026-11-11 |

## Converted with the converter

| Original | Converted | By hand |
|---|---|---|
| `lib/aullar/`, with its specs | 2026-11-11 | `view`'s two reads forcing a lazy computation, and a loop as a value in `buffer_spec` |
| `lib/ljglibs/`, with its specs | 2026-11-11 | Nothing |
| `lib/howlscript/spec/` | 2026-11-11 | Nothing; snippets containing `]]` became quoted strings |
| `lib/scripts/` | 2026-11-11 | The paths to them in `bin/`, and the Howl sources `screen-shooter` opens |
| `bundles/`, but for their `misc/` examples | 2026-11-11 | vi's functions given to `apply` and the like, whose `editor` parameter shadowed the caller's, became `ed`; a loop as a value in `pascal_lexer` |
| `lib/howl/` and `spec/`, but for PropertyObject | 2026-11-11 | The `export`s of `spec_helper` and `highlight`, and of `bindings` and `lpeg_lexer`, which dropped their `setfenv`; loops as values in `app_commands`, `edit_commands`, `lsp/edits`, `project`, `paths`, `theme`, `matcher` and `matcher_spec`; an `if` value in `search_view`'s table |
