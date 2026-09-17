{:type} = _G

export *

require 'howl.ustring'
r = require 'howl.regex'

_orig_coro_create = coroutine.create
_tracked_coroutines = setmetatable {}, __mode: 'k'

coroutine.create = (f) ->
  co = _orig_coro_create f
  _tracked_coroutines[co] = true
  co

nr_active_coroutines = ->
  count = 0
  for co in pairs _tracked_coroutines
    count += 1 if coroutine.status(co) != 'dead'
  count

callable = (o) ->
  return true if type(o) == 'function'
  mt = getmetatable o
  return (mt and mt.__call) != nil

typeof = (v) ->
  t = type v
  if t == 'cdata'
    return 'regex' if r.is_instance v
  elseif t == 'table'
    mt = getmetatable v
    if mt
      t = rawget mt, '__type'
      return t if t
      cls = rawget mt, '__class' if mt
      return cls.__name if cls
  t
