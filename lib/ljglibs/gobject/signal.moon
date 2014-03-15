-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
C, ffi_string = ffi.C, ffi.string
unpack = table.unpack

ref_id_cnt = 0
weak_handler_id_cnt = 0
handles = {}
unrefed_handlers = setmetatable {}, __mode: 'v'
options = {
  dispatch_in_coroutine: false
}

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

      if options.dispatch_in_coroutine
        target = handler
        handler = coroutine.wrap (...) -> target ...

      status, ret = pcall handler, unpack(args, 1, args.maxn + handle.args.maxn)
      return ret == true if status
      error "*error in '#{handle.signal}' handler: #{ret}"
    else
      disconnect handle

  false

register_callback = (signal, handler, instance, ...) ->
  ref_id_cnt += 1
  handle = {
    :signal
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
  void5: cb_cast 'GVCallback5', (a1, a2, a3, a4, data) -> dispatch data, a1, a2, a3, a4
  void6: cb_cast 'GVCallback6', (a1, a2, a3, a4, a5, data) -> dispatch data, a1, a2, a3, a4, a5
  void7: cb_cast 'GVCallback7', (a1, a2, a3, a4, a5, a6, data) -> dispatch data, a1, a2, a3, a4, a5, a6
  bool1: cb_cast 'GBCallback1', (data) -> dispatch data
  bool2: cb_cast 'GBCallback2', (a1, data) -> dispatch data, a1
  bool3: cb_cast 'GBCallback3', (a1, a2, data) -> dispatch data, a1, a2
  bool4: cb_cast 'GBCallback4', (a1, a2, a3, data) -> dispatch data, a1, a2, a3
  bool5: cb_cast 'GBCallback5', (a1, a2, a3, a4, data) -> dispatch data, a1, a2, a3, a4
  bool6: cb_cast 'GBCallback6', (a1, a2, a3, a4, a5, data) -> dispatch data, a1, a2, a3, a4, a5
  bool7: cb_cast 'GBCallback7', (a1, a2, a3, a4, a5, a6, data) -> dispatch data, a1, a2, a3, a4, a5, a6
 }

{
  -- GConnectFlags
  CONNECT_AFTER: C.G_CONNECT_AFTER,
  CONNECT_SWAPPED: C.G_CONNECT_SWAPPED

  -- GSignalFlags
  RUN_FIRST: C.G_SIGNAL_RUN_FIRST
  RUN_LAST: C.G_SIGNAL_RUN_LAST
  RUN_CLEANUP: C.G_SIGNAL_RUN_CLEANUP
  NO_RECURSE: C.G_SIGNAL_NO_RECURSE
  DETAILED: C.G_SIGNAL_DETAILED
  ACTION: C.G_SIGNAL_ACTION
  NO_HOOKS: C.G_SIGNAL_NO_HOOKS
  MUST_COLLECT: C.G_SIGNAL_MUST_COLLECT
  DEPRECATED: C.G_SIGNAL_DEPRECATED

  connect: (cb_type, instance, signal, handler, ...) ->
    cb = callbacks[cb_type]
    error "Unknown callback type '#{cb_type}'" unless cb
    handle = register_callback signal, handler, instance, ...
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
      handler

  emit_by_name: (instance, signal, ...) ->
    C.g_signal_emit_by_name ffi.cast('gpointer', instance), signal, ..., nil

  lookup: (name, gtype) ->
    C.g_signal_lookup name, gtype

  list_ids: (gtype) ->
    error 'Undefined gtype passed in (zero)', 2 if gtype == 0 or gtype == nil
    n_ids = ffi.new 'guint [1]'
    id_ptr = C.g_signal_list_ids gtype, n_ids
    ids = {}
    for i = 0, n_ids[0] - 1
      ids[#ids + 1] = (id_ptr + i)[0]
    ids

  query: (signal_id) ->
    query = ffi.new 'GSignalQuery'
    C.g_signal_query signal_id, query
    return nil if query.signal_id == 0

    param_types = {}
    for i = 0, query.n_params - 1
      param_types[#param_types + 1] = (query.param_types + i)[0]

    info = {
      :signal_id,
      signal_name: ffi_string query.signal_name
      itype: query.itype
      signal_flags: query.signal_flags
      return_type: query.return_type
      n_params: query.n_params
      :param_types
    }
    info

  configure: (opts) ->
    options[k] = v for k,v in pairs opts

}
