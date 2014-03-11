-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

require 'ljglibs.cdefs.glib'
ffi = require 'ffi'
C = ffi.C
unpack = table.unpack

ref_id_cnt = 0
callbacks = {}

g_callback = ffi.cast 'GSourceFunc', (data) ->
  ref_id = tonumber ffi.cast('gint', data)
  cb = callbacks[ref_id]
  if cb
    co = coroutine.create (...) -> cb[1] ...
    status, ret = coroutine.resume co, unpack(cb[2], 1, cb[2].maxn)

    unless status
      _G.log.error 'Error invoking timer handler: ' .. ret
  false

register_callback = (f, ...) ->
  ref_id_cnt += 1
  args = {...}
  args.maxn = select '#', ...
  callbacks[ref_id_cnt] = { f, args }
  ffi.cast 'gpointer', ref_id_cnt

asap = (f, ...) ->
  cb_id = register_callback f, ...
  C.g_idle_add_full C.G_PRIORITY_LOW, g_callback, cb_id, nil

after = (seconds, f, ...) ->
  cb_id = register_callback f, ...
  interval = seconds * 1000
  C.g_timeout_add_full C.G_PRIORITY_LOW, interval, g_callback, cb_id, nil

{
  :asap
  :after
}
