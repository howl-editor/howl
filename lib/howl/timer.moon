-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:signal, :config} = howl
callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
jit = require 'jit'
C = ffi.C
timer_callback = callbacks.source_func
{:pack, :unpack, :remove} = table

jit.off true, true

idle_handlers = {}
idle_fired = 0

check_for_idle = ->
  idle = howl.app.idle
  unless idle >= 1
    idle_fired = 0
    return

  fired = {}
  for i = 1, #idle_handlers
    h = idle_handlers[i]
    if h.seconds <= idle and h.seconds > idle_fired
      co = coroutine.create (...) -> h.handler ...
      status, ret = coroutine.resume co, unpack(h.args)
      unless status
        _G.log.error "Error invoking on_idle handler: '#{ret}'"

      fired[#fired + 1] = i

  for i = #fired, 1, -1
    table.remove idle_handlers, i

  idle_fired = idle

every_second = ->
  check_for_idle!
  true

cancel = (handle) ->
  if handle.type == 'sys'
    if callbacks.unregister handle.cb
      C.g_source_remove handle.tag
  elseif handle.type == 'idle'
    idle_handlers = [h for h in *idle_handlers when h != handle]

asap = (f, ...) ->
  t_handle = type: 'sys'

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
  t_handle = type: 'sys'

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

on_idle = (seconds, f, ...) ->
  t_handle = {
    type: 'idle',
    :seconds,
    handler: f,
    args: pack ...
  }
  idle_handlers[#idle_handlers + 1] = t_handle
  t_handle

-- set up a shared timer to run every second
second_handle = {}
second_handle.cb = callbacks.register every_second, "timer-every-second"
second_handle.tag = C.g_timeout_add_full C.G_PRIORITY_LOW,
  1000,
  timer_callback,
  cast_arg(second_handle.cb.id),
  nil

{
  :after
  :asap
  :cancel
  :on_idle
}
