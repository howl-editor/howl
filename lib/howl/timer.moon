-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
jit = require 'jit'
C = ffi.C

timer_callback = callbacks.source_func

jit.off true, true

cancel = (handle) ->
  if callbacks.unregister handle.cb
    C.g_source_remove handle.tag

asap = (f, ...) ->
  t_handle = {}

  handler = (...) ->
    cancel t_handle
    f ...

  t_handle.cb = callbacks.register handler, 'timer-asap', ...
  t_handle.tag = C.g_idle_add_full C.G_PRIORITY_LOW, timer_callback, cast_arg(t_handle.cb.id), nil
  t_handle

after = (seconds, f, ...) ->
  t_handle = {}

  handler = (...) ->
    cancel t_handle
    f ...

  interval = seconds * 1000
  t_handle.cb = callbacks.register f, "timer-after-#{seconds}", ...
  t_handle.tag = C.g_timeout_add_full C.G_PRIORITY_LOW, interval, timer_callback, cast_arg(t_handle.cb.id), nil
  t_handle

{
  :after
  :asap
  :cancel
}
