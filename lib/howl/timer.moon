-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
jit = require 'jit'
C = ffi.C
timer_callback = callbacks.source_func
{:pack, :unpack} = table
{:get_monotonic_time} = require 'ljglibs.glib'
{:abs} = math

jit.off true, true

TICK_INTERVAL = 500

idle_handlers = {}
tick_handlers = {}
idle_fired = 0
last_idle = 0

check_for_idle = ->
  idle = howl.app.idle
  if (last_idle + 0.4) > idle
    idle_fired = 0

  last_idle = idle
  return unless idle >= 0.5

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
    table.remove idle_handlers, fired[i]

  idle_fired = idle

cancel = (handle) ->
  if handle.type == 'sys'
    if callbacks.unregister handle.cb
      C.g_source_remove handle.tag
  elseif handle.type == 'idle'
    idle_handlers = [h for h in *idle_handlers when h != handle]
  elseif handle.type == 'tick'
    tick_handlers = [h for h in *tick_handlers when h != handle]

every_tick = ->
  check_for_idle!

  now = get_monotonic_time!

  for i = #tick_handlers, 1, -1
    h = tick_handlers[i]
    elapsed = (now - h.start) / 1000
    run_now_diff = abs(h.after_ms - elapsed)
    run_next_diff = abs(h.after_ms - (elapsed + TICK_INTERVAL))

    continue if run_next_diff < run_now_diff

    table.remove tick_handlers, i
    co = coroutine.create (...) -> h.handler ...
    status, ret = coroutine.resume co, unpack(h.args)
    unless status
      _G.log.error "Error invoking tick handler: '#{ret}'"

  true

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

after_exactly = (seconds, f, ...) ->
  t_handle = type: 'sys'
  interval = seconds * 1000
  t_handle.cb = callbacks.register f, "timer-after-#{seconds}", ...
  t_handle.tag = C.g_timeout_add_full C.G_PRIORITY_LOW,
    interval,
    timer_callback,
    cast_arg(t_handle.cb.id),
    nil
  t_handle

after_approximately = (seconds, f, ...) ->
  t_handle = {
    type: 'tick',
    after_ms: seconds * 1000,
    start: get_monotonic_time!
    handler: f,
    args: pack ...
  }
  tick_handlers[#tick_handlers + 1] = t_handle
  t_handle

after = (seconds, f, ...) ->
  if seconds != 0 and (math.floor(seconds) == seconds or seconds >= 2)
    after_approximately seconds, f, ...
  else
    after_exactly seconds, f, ...

on_idle = (seconds, f, ...) ->
  t_handle = {
    type: 'idle',
    :seconds,
    handler: f,
    args: pack ...
  }
  idle_handlers[#idle_handlers + 1] = t_handle
  t_handle

-- set up a shared timer to run repeatedly
tick_handle = {}
tick_handle.cb = callbacks.register every_tick, "timer-tick"
tick_handle.tag = C.g_timeout_add_full C.G_PRIORITY_LOW,
  TICK_INTERVAL,
  timer_callback,
  cast_arg(tick_handle.cb.id),
  nil

{
  :after
  :after_exactly
  :after_approximately
  :asap
  :cancel
  :on_idle
}
