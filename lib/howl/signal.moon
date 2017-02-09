-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

handlers = {}
all = {}
append = table.insert
abort = {}

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
    co = coroutine.create (...) ->
      howl.util.safecall "Error invoking handler for '#{name}'", handler, ...
    _, status, ret = coroutine.resume co, params

    if status
      if ret == abort and coroutine.status(co) == 'dead'
        return abort

  false

connect = (name, handler, index) ->
  error "Unknown signal '#{name}'", 2 unless all[name]

  list = handlers_for name
  if not index or index > #list + 1 then index = #list + 1
  else if index < 1 then index = 1
  append list, index, handler

disconnect = (name, handler) ->
  handlers[name] = [h for h in *handlers_for name when h != handler]

return :abort, :register, :unregister, :emit, :connect, :disconnect, :all
