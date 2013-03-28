import type from _G

export *

require 'howl.ustring'
r = require 'howl.regex'

callable = (o) ->
  return true if type(o) == 'function'
  mt = getmetatable o
  return (mt and mt.__call) != nil

append = table.insert

typeof = (v) ->
  t = type v
  if t == 'cdata'
    return 'regex' if r.is_instance v
  elseif t == 'table'
    mt = getmetatable v
    cls = rawget mt, '__class' if mt
    return cls.__name if cls
  t
