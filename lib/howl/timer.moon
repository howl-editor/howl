-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
jit = require 'jit'
C = ffi.C

timer_callback = ffi.cast 'GSourceFunc', callbacks.bool1

jit.off true

asap = (f, ...) ->
  handle = callbacks.register f, 'timer-asap', ...
  C.g_idle_add_full C.G_PRIORITY_LOW, timer_callback, cast_arg(handle.id), nil

after = (seconds, f, ...) ->
  handle = callbacks.register f, "timer-after-#{seconds}", ...
  interval = seconds * 1000
  C.g_timeout_add_full C.G_PRIORITY_LOW, interval, timer_callback, cast_arg(handle.id), nil

{
  :asap
  :after
}
