handlers = {}

handlers_for = (name) ->
  handlers[name] = handlers[name] or {}
  handlers[name]

emit = (name, ...) ->
  for handler in *handlers_for name
    status, ret = pcall handler, ...
    if not status and name != 'error'
      emit 'error', 'Error invoking handler for "' .. name .. '": ' .. ret
    return true if status and ret
  false

connect = (name, handler, index) ->
  list = handlers_for name
  if not index or index > #list + 1 then index = #list + 1
  else if index < 1 then index = 1
  table.insert list, index, handler

connect_first = (name, handler) ->
  connect name, handler, 1

disconnect = (name, handler) ->
  handlers[name] = [h for h in *handlers_for name when h != handler]

return :emit, :connect, :connect_first, :disconnect
