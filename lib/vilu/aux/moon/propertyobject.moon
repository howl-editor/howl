class_properties = (cls) ->
  cls.__base.__properties = {} if not cls.__base.__properties
  cls.__base.__properties

meta_methods = (cls) ->
  cls.__base.__metas = {} if not cls.__base.__metas
  cls.__base.__metas

__index = (key) =>
  base = getmetatable self
  prop = base.__properties[key]
  if prop and prop.get then return prop.get self
  base[key]

__newindex = (key, value) =>
  base = getmetatable self
  prop = base.__properties[key]
  if prop
    if prop.set
      prop.set self, value
    else
      error 'Attempt to set read-only property "' .. key .. '"', 1
  else
    rawset self, key, value

class PropertyObject
  new: =>
    base = getmetatable self
    rawset base, '__properties', base.__properties or {}
    base.__index = __index
    base.__newindex = __newindex
    for k, v in pairs base.__metas or {}
      rawset base, k, v

  property: (cls, tbl) ->
    properties = class_properties cls
    properties[k] = v for k,v in pairs tbl

  meta: (cls, tbl) ->
    metas = meta_methods cls
    metas[k] = v for k,v in pairs tbl

return PropertyObject
