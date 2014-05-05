busted = require 'busted'
say = require('say')
C = require('ffi').C

import File from howl.io
import theme from howl.ui
import signal, config from howl
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

howl_main_ctx = C.g_main_context_default!
howl_loop = setmetatable {
    step: (...) ->
      jit.off!
      C.g_main_context_iteration(howl_main_ctx, false)
      default_loop.step!

    pcall: pcall
  }, __index: default_loop

export set_howl_loop = -> setloop howl_loop
