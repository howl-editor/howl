init_properties = (base) ->
  base.__properties = {}

  base.__index = (key) =>
    val = base[key]
    return val if val
    prop = base.__properties[key]
    return nil if not prop or not prop.get
    prop.get self

  base.__newindex = (key, value) =>
    prop = base.__properties[key]
    if prop
      if prop.set
        prop.set self, value
      else
        error 'Attempt to set read-only property "' .. key .. '"', 1
    else
      rawset self, key, value

  base.__properties

class PropertyObject
  property: (cls, tbl) ->
    properties = cls.__base.__properties or init_properties(cls.__base)
    properties[k] = v for k,v in pairs tbl

return PropertyObject
