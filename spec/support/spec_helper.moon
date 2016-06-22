busted = require 'busted'
say = require('say')
C = require('ffi').C

import File from howl.io
import theme from howl.ui
import dispatch, signal, config from howl
_G.Spy = require 'howl.spec.spy'

-- additional aliases
export context = describe

-- includes assertion
includes = (state, args) ->
  t, b = table.unpack args
  if type(t) == 'string'
    return t\contains(b), args

  error 'Not a table', 1 if type(t) != 'table'
  for v in *t
    if v == b
      return true, args
  return false, args

say\set("assertion.includes.positive", "Expected '%s' to include '%s'")
say\set("assertion.includes.negative", "Expected '%s' to not include '%s'")
assert\register("assertion", "includes", includes, "assertion.includes.positive", "assertion.includes.negative")

-- match assertion
match = (state, args) ->
  target, pattern = table.unpack args
  return target\match(pattern) != nil, { target, pattern }

say\set("assertion.match.positive", "Expected '%s' to match '%s'")
say\set("assertion.match.negative", "Expected '%s' to not match '%s'")
assert\register("assertion", "match", match, "assertion.match.positive", "assertion.match.negative")

-- raises assertion
raises = (state, args) ->
  pattern, f = table.unpack args
  error 'Not a function', 2 if type(f) != 'function'
  status, raised_error = pcall f
  raised_error = raised_error or '<no-error>'
  val = not status and raised_error.ulower\match(pattern.ulower) != nil
  return val, { pattern }

say\set("assertion.raises.positive", "Function raised no error matching '%s'")
say\set("assertion.raises.negative", "Function did raise an error matching '%s'")
assert\register("assertion", "raises", raises, "assertion.raises.positive", "assertion.raises.negative")

-- helpers
export with_tmpdir = (f) ->
  dir = File.tmpdir!
  status, err = pcall f, dir
  dir\delete_all! if dir.exists
  error err if not status

export with_signal_handler = (name, ret, f) ->
  handler = spy.new -> ret
  signal.connect name, handler
  status, err = pcall f, handler
  signal.disconnect name, handler
  error err if not status

root = howl.app.root_dir
support_files = root / 'spec' / 'support'

-- load basic theme for specs
theme.register('spec_theme', support_files / 'spec_theme.moon')
config.theme = 'spec_theme'
theme.apply!

-- catch any errors and store them in _G.errors
-- export errors = {}
-- signal.connect_first 'error', (e) ->
--   append errors, e
--   true


default_loop = require'busted.loop.default'

export howl_main_ctx = C.g_main_context_default!
howl_loop = setmetatable {
    step: (...) ->
      jit.off true, false
      C.g_main_context_iteration(howl_main_ctx, false)
      default_loop.step!

    pcall: pcall
  }, __index: default_loop

export set_howl_loop = -> _G.setloop howl_loop

export howl_async = (f) ->
  _G.setloop howl_loop
  co = coroutine.create busted.async(f)
  status, err = coroutine.resume co
  error err unless status

export pump_mainloop = ->
  jit.off true, true
  count = 0
  while count < 100 and C.g_main_context_iteration(howl_main_ctx, false) != 0
    count += 1

export within_activity = (activity_function, on_show) ->
  command_line = howl.app.window.command_line
  command_line.orig_show = command_line.show
  command_line.show = spy.new =>
    @orig_show!
    on_show!

  ok, error = dispatch.launch activity_function
  if not ok
    print error

  command_line.show = command_line.orig_show

export get_ui_list_widget_column = (column=1, widget_name='completion_list') ->
  items = howl.app.window.command_line\get_widget(widget_name).items
  items = [row[column] for row in *items]
  return [item.text or item for item in *items]

export close_all_buffers = ->
  for b in *howl.app.buffers
    howl.app\close_buffer b, true

export collect_memory = ->
  mem = collectgarbage('count')
  while true
    collectgarbage!
    used = collectgarbage('count')
    break if used >= mem
    mem = used

export assert_memory_stays_within = (units, iterations, f) ->
  val, unit = units\match '(%d+)(%S+)'
  if not (val and unit) and (unit == '%' or unit == 'Kb')
    error "Unknown unit specifier '#{units}'"

  val = tonumber val
  f!
  collect_memory!
  baseline = math.ceil(collectgarbage 'count')
  total_used = 0

  for i = 1, iterations
    f!
    collect_memory!
    used = math.ceil(collectgarbage 'count')
    total_used += used

  avg_used = total_used / iterations
  diff = avg_used - baseline
  percentual = (diff / baseline) * 100
  if diff > 0
    if (unit == '%' and percentual > val) or (unit == 'Kb' and diff > val)
      err = string.format "Memory increased on average from %dKb -> %dKb (diff = %dKb, %.2f%%)",
        baseline, avg_used, diff, percentual
      error err

