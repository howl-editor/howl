-- Copyright 2014-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
ffi_cast = ffi.cast
{:unpack, :pack, :insert} = table
{match: string_match, gsub: string_gsub} = string

ref_id_cnt = 1
handles = {}
handle_count = 0

destructor_t = ffi.typeof('struct {}')
destructor = (f) ->
  v = destructor_t()
  ffi.gc(v, f)

options = {
  on_error: (e) ->
    error e
}

cb_cast = (cb_type, handler) -> ffi_cast('GCallback', ffi_cast(cb_type, handler))

unregister = (handle) ->
  error "callbacks.unregister(): Missing argument #1 (handle)", 2 unless handle
  return false unless handles[handle.id]
  handle_count -= 1
  handles[handle.id] = nil
  true

do_dispatch = (data, ...) ->
  ref_id = tonumber ffi_cast('gint', data)
  handle = handles[ref_id]
  unless handle
    print "no handler found for #{ref_id}"
    return false

  instance = nil

  if handle.instance
    instance = next(handle.instance)

    unless instance
      unregister handle
      return false

  handler = handle.handler
  handler_args = handle.args

  args = pack ...

  if instance
    insert args, 1, instance
    args.n += 1

  if options.dispatcher
    insert args, 1, handler
    insert args, 2, handle.description
    args.n += 2
    handler = options.dispatcher

  for i = 1, handler_args.n
    args[args.n + i] = handler_args[i]

  status, ret = pcall handler, unpack(args, 1, args.n + handler_args.n)
  return ret == true if status
  print "error: #{ret}"
  moon.p debug.traceback!
  options.on_error "callbacks: error in '#{handle.description}' handler: '#{ret}'"
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

register = (handler, description, ...) ->
  if not handler
    error "Missing handler for #{description}"

  handle_count += 1
  ref_id_cnt += 1
  handle = {
    :handler,
    :description,
    id: ref_id_cnt,
    args: pack ...
  }
  handles[ref_id_cnt] = handle
  handle

callbacks = {
  :dispatch
  :register

  count: -> handle_count

  register_for_instance: (instance, handler, description, ...) ->
    handle = register handler, description, ...
    handle.instance = setmetatable {
      [instance]: destructor(->
        -- print "destructor, unregister #{handle.description}"
        unregister handle
      )
    }, __mode: 'k'
    handle

  :unregister

  cast_arg: (arg) -> ffi.cast('gpointer', arg)

  configure: (opts) ->
    options = moon.copy opts

  -- predefined callbacks
  void2: cb_cast 'GVCallback2', (a1, data) -> dispatch data, a1
  void3: cb_cast 'GVCallback3', (a1, a2, data) -> dispatch data, a1, a2
  void5: cb_cast 'GVCallback5', (a1, a2, a3, a4, data) -> dispatch data, a1, a2, a3, a4
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
