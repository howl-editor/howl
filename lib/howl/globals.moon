export *

u = require('howl.ustring')
r = require('howl.regex')

callable = (o) ->
  return true if type(o) == 'function'
  mt = getmetatable o
  return (mt and mt.__call) != nil

append = table.insert
