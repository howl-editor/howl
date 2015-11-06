-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
jit = require 'jit'
C = ffi.C

timer_callback = ffi.cast 'GSourceFunc', callbacks.bool1

jit.off true, true

asap = (f, ...) ->
  local handle, tag

  handler = (...) ->
    callbacks.unregister handle
    C.g_source_remove tag
    f ...

  handle = callbacks.register handler, 'timer-asap', ...
  tag = C.g_idle_add_full C.G_PRIORITY_LOW, timer_callback, cast_arg(handle.id), nil

after = (seconds, f, ...) ->
  local handle, tag

  handler = (...) ->
    callbacks.unregister handle
    C.g_source_remove tag
    f ...

  handle = callbacks.register f, "timer-after-#{seconds}", ...
  interval = seconds * 1000
  tag = C.g_timeout_add_full C.G_PRIORITY_LOW, interval, timer_callback, cast_arg(handle.id), nil

{
  :asap
  :after
}
