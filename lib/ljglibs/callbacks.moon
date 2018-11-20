-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
ffi_cast = ffi.cast
{:unpack, :pack, :insert} = table

ref_id_cnt = 0
weak_handler_id_cnt = 0
handles = {}
unrefed_handlers = setmetatable {}, __mode: 'v'
unrefed_args = setmetatable {}, __mode: 'k'
options = {
  dispatch_in_coroutine: false
  on_error: error
}

cb_cast = (cb_type, handler) -> ffi_cast('GCallback', ffi_cast(cb_type, handler))

unregister = (handle) ->
  error "callbacks.unregister(): Missing argument #1 (handle)", 2 unless handle
  return false unless handles[handle.id]
  unrefed_handlers[handle.handler] = nil if type(handle.handler) == 'number'
  handles[handle.id] = nil
  true

do_dispatch = (data, ...) ->
  ref_id = tonumber ffi_cast('gint', data)
  handle = handles[ref_id]
  if handle
    handler = handle.handler
    handler_args = handle.args

    if type(handler) == 'number'
      handler = unrefed_handlers[handler]
      handler_args = unrefed_args[handler]

    if handler
      args = pack ...

      if options.dispatcher
        insert args, 1, handler
        insert args, 2, handle.description
        args.n += 2
        handler = options.dispatcher

      for i = 1, handler_args.n
        args[args.n + i] = handler_args[i]

      status, ret = pcall handler, unpack(args, 1, args.n + handler_args.n)
      return ret == true if status
      options.on_error "callbacks: error in '#{handle.description}' handler: '#{ret}'"
    else
      unregister handle

  false

dispatch = (data, ...) ->
  status, ret = pcall do_dispatch, data, ...
  unless status
    options.on_error "callbacks: error in dispatch: '#{ret}'"
    return false

  ret

{

  register: (handler, description, ...) ->
    ref_id_cnt += 1
    handle = {
      :handler,
      :description,
      id: ref_id_cnt,
      args: pack ...
    }
    handles[ref_id_cnt] = handle
    handle

  :unregister

  unref_handle: (handle) ->
    handler = handle.handler
    if type(handler) != 'number'
      weak_handler_id_cnt += 1
      unrefed_handlers[weak_handler_id_cnt] = handler
      unrefed_args[handler] = handle.args
      handle.handler = weak_handler_id_cnt
      handle.args = nil
      handler

  cast_arg: (arg) -> ffi.cast('gpointer', arg)

  configure: (opts) ->
    options = moon.copy opts

  -- different callbacks
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
  int3:  cb_cast 'GICallback3', (a1, a2, data) -> dispatch data, a1, a2
  source_func: ffi_cast 'GSourceFunc', (data) -> dispatch data
}
