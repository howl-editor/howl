-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:signal, :config} = howl
callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
jit = require 'jit'
C = ffi.C

timer_callback = callbacks.source_func

jit.off true, true

idle_fired = false

check_for_idle = ->
  app = howl.app
  if app.idle > config.idle_timeout
    if not idle_fired
      idle_fired = true
      signal.emit 'idle'
  else
    idle_fired = false

every_second = ->
  check_for_idle!
  signal.emit 'every-second'
  true

cancel = (handle) ->
  if callbacks.unregister handle.cb
    C.g_source_remove handle.tag

asap = (f, ...) ->
  t_handle = {}

  handler = (...) ->
    cancel t_handle
    f ...

  t_handle.cb = callbacks.register handler, 'timer-asap', ...
  t_handle.tag = C.g_idle_add_full C.G_PRIORITY_LOW,
    timer_callback,
    cast_arg(t_handle.cb.id),
    nil
  t_handle

after = (seconds, f, ...) ->
  t_handle = {}

  handler = (...) ->
    cancel t_handle
    f ...

  interval = seconds * 1000
  t_handle.cb = callbacks.register f, "timer-after-#{seconds}", ...
  t_handle.tag = C.g_timeout_add_full C.G_PRIORITY_LOW,
    interval,
    timer_callback,
    cast_arg(t_handle.cb.id),
    nil
  t_handle

-- set up a shared timer to run every second
second_handle = {}
second_handle.cb = callbacks.register every_second, "timer-every-second"
second_handle.tag = C.g_timeout_add_full C.G_PRIORITY_LOW,
  1000,
  timer_callback,
  cast_arg(second_handle.cb.id),
  nil

signal.register 'idle',
  description: 'Signaled once whenever Howl becomes idle'

signal.register 'every-second',
  description: 'Signaled once every second'

config.define
  name: 'idle_timeout'
  description: 'Number of idle time in seconds before the "idle" signal is fired'
  default: 60
  type_of: 'number'
  scope: 'global'

{
  :after
  :asap
  :cancel
}
