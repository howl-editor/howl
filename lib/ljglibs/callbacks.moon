-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
ffi_cast = ffi.cast
{:unpack, :pack, :insert} = table
{match: string_match, gsub: string_gsub} = string

-- ffi.cdef "
-- typedef void (*hcb_void_gpointer_gpointer) (gpointer, gpointer);
-- typedef gboolean (*hcb_gboolean_gpointer_gpointer) (gpointer, gpointer);
-- "

ref_id_cnt = 123
weak_handler_id_cnt = 0
handles = {}
unrefed_handlers = setmetatable {}, __mode: 'v'
unrefed_args = setmetatable {}, __mode: 'k'
options = {
  dispatch_in_coroutine: false
  on_error: (e) ->
    print "callbacks err: #{e}"
    error e
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
  else
    print "Unknown handle id: #{ref_id}"

  false

dispatch = (data, ...) ->
  status, ret = pcall do_dispatch, data, ...

  unless status
    print "callbacks err: #{ret}"
    options.on_error "callbacks: error in dispatch: '#{ret}'"
    return false

  ret

create_callback = (t, orig_signature) ->
  signature = string_gsub orig_signature, '%s+', ''
  -- print "Create callback: #{signature}"
  ret, arg_list = string_match signature, '^([^(]+)%(([^)]+)%)$'
  simple_args = string_gsub(arg_list, '%s*%*', '')
  simple_args = string_gsub(simple_args, ',', '_')
  def_name = "hcb_#{ret}_#{simple_args}"
  cdef = "typedef #{ret} (*#{def_name})(#{arg_list});"
  ffi.cdef cdef

  cb = cb_cast(
    def_name,
    (...) ->
      args = pack ...
      user_data = args[args.n]
      dispatch user_data, unpack(args, 1, args.n - 1)
  )
  rawset t, signature, cb
  if signature != orig_signature
    rawset t, orig_signature, cb

  cb

callbacks = {
  :dispatch

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

  -- predefined callbacks
  -- hcb_void_gpointer_gpointer: cb_cast(
  --   'hs_void_gpointer_gpointer',
  --   (ptr, data) ->  dispatch data, ptr
  -- ),

  -- 'hcb_gboolean_gpointer_gpointer': cb_cast(
  --   'hs_gboolean_gpointer_gpointer',
  --   (instance, data) ->  callbacks.dispatch data, instance
  -- )


  -- void1: cb_cast 'GVCallback1', (data) -> dispatch data
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
setmetatable callbacks, __index: create_callback

callbacks
