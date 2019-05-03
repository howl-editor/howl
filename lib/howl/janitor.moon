-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:config, :timer, :sys} = howl
ffi = require 'ffi'

config.define
  name: 'cleanup_min_buffers_open'
  description: 'The minimum number of buffers to leave when auto-closing buffers'
  default: 40
  type_of: 'number'
  scope: 'global'

config.define
  name: 'cleanup_close_buffers_after'
  description: 'The number of hours since a buffer was last shown before it can be closed'
  default: 24
  type_of: 'number'
  scope: 'global'

if sys.info.os == 'linux'
  ffi.cdef 'int malloc_trim(size_t pad);'

local timer_handle

log_closed = (closed) ->
  msg = "Closed buffers: '#{closed[1].title}'"
  for i = 2, #closed
    t = closed[i].title
    if #t + #msg > 72
      msg ..= " (+#{#closed - i + 1} more)"
      break

    msg ..= ", '#{t}'"

  log.info msg

clean_up_buffers = ->
  app = howl.app
  bufs = app.buffers
  to_remove = #bufs - config.cleanup_min_buffers_open
  return if to_remove <= 0
  now = sys.time!
  closeable = {}

  for b in *bufs
    continue if b.modified or not b.last_shown
    unseen_for = os.difftime(now, b.last_shown) / 60 / 60 -- hours
    if unseen_for > config.cleanup_close_buffers_after
      closeable[#closeable + 1] = b

  to_remove = math.min(to_remove, #closeable)
  if to_remove > 0
    closed = {}
    table.sort closeable, (a, b) -> a.last_shown < b.last_shown
    for i = 1, to_remove
      buf = closeable[i]
      app\close_buffer buf
      closed[#closed + 1] = buf

    log_closed closed

release_memory = ->
  collectgarbage!
  collectgarbage!

  if sys.info.os == 'linux'
    ffi.C.malloc_trim(1024 * 128)

run = ->
  if timer_handle
    timer_handle = timer.on_idle 30, run

  window = howl.app.window
  if window and not window.command_panel.is_active
    clean_up_buffers!

    howl.app\save_session!

  release_memory!

start = ->
  return if timer_handle
  timer_handle = timer.on_idle 30, run

stop = ->
  return unless timer_handle
  timer.cancel timer_handle
  timer_handle = nil

{
  :clean_up_buffers
  :start
  :stop
  :run
}
