-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

require 'howl.cdefs.glib'
ffi = require 'ffi'
C = ffi.C
unpack = table.unpack

ref_id_cnt = 0
callbacks = {}

asap_cb = ffi.cast 'GSourceFunc', (data) ->
  ref_id = tonumber ffi.cast('gint', data)
  cb = callbacks[ref_id]
  if cb
    status, ret = pcall cb[1], unpack(cb[2], 1, cb[2].maxn)

  false

asap = (f, ...) ->
  ref_id_cnt += 1
  args = {...}
  args.maxn = select '#', ...
  data = ffi.cast 'gpointer', ref_id_cnt
  callbacks[ref_id_cnt] = { f, args }
  C.g_idle_add_full C.G_PRIORITY_LOW, asap_cb, data, nil

{
  :asap
}
