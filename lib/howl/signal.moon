-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

handlers = {}
all = {}
append = table.insert

register = (name, options = {}) ->
  error "Missing field 'description'", 2 unless options.description
  all[name] = options

unregister = (name) ->
  all[name] = nil
  handlers[name] = nil

handlers_for = (name) ->
  handlers[name] = handlers[name] or {}
  handlers[name]

emit = (name, params, illegal) ->
  error "Unknown signal '#{name}'", 2 unless all[name]
  error "emit can be called with a maximum of two parameters", 2 if illegal
  error "expected table as second parameter", 2 if params and type(params) != 'table'

  for handler in *handlers_for name
    co = coroutine.create (...) -> handler ...
    status, ret = coroutine.resume co, params

    if status
      return true if ret == true and coroutine.status(co) == 'dead'
    else
      _G.log.error 'Error invoking handler for "' .. name .. '": ' .. ret

  false

connect = (name, handler, index) ->
  error "Unknown signal '#{name}'", 2 unless all[name]

  list = handlers_for name
  if not index or index > #list + 1 then index = #list + 1
  else if index < 1 then index = 1
  append list, index, handler

disconnect = (name, handler) ->
  handlers[name] = [h for h in *handlers_for name when h != handler]

return :register, :unregister, :emit, :connect, :disconnect, :all
