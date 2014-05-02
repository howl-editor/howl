-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
callbacks = require 'ljglibs.callbacks'
C, ffi_string = ffi.C, ffi.string

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
    handle = callbacks.register handler, "signal #{signal}", ...
    handler_id = C.g_signal_connect_data(instance, signal, cb, callbacks.cast_arg(handle.id), nil, 0)
    handle.signal_handler_id = handler_id
    handle.signal_object_instance = instance
    handle

  disconnect: (handle) ->
    callbacks.unregister handle
    C.g_signal_handler_disconnect handle.signal_object_instance, handle.signal_handler_id

  unref_handle: (handle) ->
    callbacks.unref_handle handle

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
}
