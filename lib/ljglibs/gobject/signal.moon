-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gobject'
{name: type_name, parent: type_parent, from_name: type_from_name} = require 'ljglibs.gobject.type'
callbacks = require 'ljglibs.callbacks'
C, ffi_string, ffi_cast = ffi.C, ffi.string, ffi.cast
{insert: append, :concat} = table

GEnumType = type_from_name('GEnum')
callbacks_by_id = {}

signal_cb_signature = (info) ->
  ret_type = type_name(info.return_type)
  parameters = {'gpointer'}
  sig = "#{ret_type}("

  for param_type in *info.param_types
    parent = type_parent(param_type)
    type = if parent == GEnumType
      'GEnum'
    else
      name = type_name param_type
      parent == 0 and name or "#{name}*"

    append parameters, type

  append parameters, 'gpointer'
  sig .. concat(parameters, ',') .. ')'

cb_for_info = (info) ->
  cb = callbacks_by_id[info.signal_id]
  return cb if cb
  signature = signal_cb_signature info
  cb = callbacks[signature]
  callbacks_by_id[info.signal_id] = cb
  cb

signal_lookup = (name, gtype) ->
  C.g_signal_lookup name, gtype

signal_query = (signal_id) ->
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

connect_by_info = (instance, info, handler, ...) ->
  cb = cb_for_info info
  sig_id = info.signal_id
  signal = info.signal_name
  handle = callbacks.register handler, "signal #{signal}(#{sig_id})", ...
  handler_id = C.g_signal_connect_data(instance, signal, cb, callbacks.cast_arg(handle.id), nil, 0)
  handle.signal_handler_id = handler_id
  handle.signal_object_instance = instance
  handle

signal = {
  :callbacks
  lookup: signal_lookup
  query: signal_query
  :connect_by_info

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

  connect: (instance, signal, handler, ...) ->
    if type(instance) == 'string'
      print debug.traceback!
      error "GTK4: removed! #{handler}"

    signal_id = signal_lookup signal, ffi_cast('GType', instance.gtype)
    info = signal_query signal_id
    connect_by_info instance, info, handler, ...

  disconnect: (handle) ->
    callbacks.unregister handle
    C.g_signal_handler_disconnect handle.signal_object_instance, handle.signal_handler_id

  unref_handle: (handle) ->
    callbacks.unref_handle handle

  emit_by_name: (instance, signal, ...) ->
    ret = ffi.new 'gboolean [1]'
    C.g_signal_emit_by_name ffi.cast('gpointer', instance), signal, ..., ret, nil
    ret[0]

  list_ids: (gtype) ->
    error 'Undefined gtype passed in (zero)', 2 if gtype == 0 or gtype == nil
    n_ids = ffi.new 'guint [1]'
    id_ptr = C.g_signal_list_ids gtype, n_ids
    ids = {}
    for i = 0, n_ids[0] - 1
      ids[#ids + 1] = (id_ptr + i)[0]
    ids
}

jit.off signal.connect_by_info
signal
