-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
C = ffi.C
unpack = table.unpack

ref_id_cnt = 0
weak_handler_id_cnt = 0
handles = {}
unrefed_handlers = setmetatable {}, __mode: 'v'

cb_cast = (cb_type, handler) -> ffi.cast('GCallback', ffi.cast(cb_type, handler))

pack_n = (...) ->
  t = {...}
  t.maxn = select '#', ...
  t

disconnect = (handle) ->
  unrefed_handlers[handle.handler] = nil if type(handle.handler) == 'number'
  handles[handle.id] = nil
  C.g_signal_handler_disconnect handle.instance, handle.handler_id

dispatch = (data, ...) ->
  ref_id = tonumber ffi.cast('gint', data)
  handle = handles[ref_id]
  if handle
    handler = handle.handler
    handler = unrefed_handlers[handler] if type(handler) == 'number'
    if handler
      args = pack_n ...
      for i = 1, handle.args.maxn
        args[args.maxn + i] = handle.args[i]

      status, ret = pcall handler, unpack(args, 1, args.maxn + handle.args.maxn)
      return ret == true if status
    else
      disconnect handle

  false

register_callback = (handler, instance, ...) ->
  ref_id_cnt += 1
  handle = {
    :handler,
    :instance,
    id: ref_id_cnt,
    args: pack_n(...)
  }
  handles[ref_id_cnt] = handle
  handle

callbacks = {
  void1: cb_cast 'GVCallback1', (data) -> dispatch data
  void2: cb_cast 'GVCallback2', (a1, data) -> dispatch data, a1
  void3: cb_cast 'GVCallback3', (a1, a2, data) -> dispatch data, a1, a2
  void4: cb_cast 'GVCallback4', (a1, a2, a3, data) -> dispatch data, a1, a2, a3
  bool1: cb_cast 'GBCallback1', (data) -> dispatch data
  bool2: cb_cast 'GBCallback2', (a1, data) -> dispatch data, a1
  bool3: cb_cast 'GBCallback3', (a1, a2, data) -> dispatch data, a1, a2
  bool4: cb_cast 'GBCallback4', (a1, a2, a3, data) -> dispatch data, a1, a2, a3
}

{
  CONNECT_AFTER: C.G_CONNECT_AFTER,
  CONNECT_SWAPPED: C.G_CONNECT_SWAPPED

  connect: (cb_type, instance, signal, handler, ...) ->
    cb = callbacks[cb_type]
    error "Unknown callback type '#{cb_type}'" unless cb
    handle = register_callback handler, instance, ...
    handler_id = C.g_signal_connect_data(instance, signal, cb, ffi.cast('gpointer', handle.id), nil, 0)
    handle.handler_id = handler_id
    handle

  :disconnect

  unref_handle: (handle) ->
    handler = handle.handler
    if type(handler) != 'number'
      weak_handler_id_cnt += 1
      unrefed_handlers[weak_handler_id_cnt] = handler
      handle.handler = weak_handler_id_cnt

  emit_by_name: (instance, signal, ...) ->
    C.g_signal_emit_by_name ffi.cast('gpointer', instance), signal, ...
}
