lookup_tables = setmetatable {}, __mode: 'k'

property_lookup_table = (obj) ->
  base = getmetatable obj
  properties = base.__properties
  return base if not properties
  t = lookup_tables[base]
  return t if t

  t = {
    __index: (key) =>
      val = base[key]
      return val if val
      prop = properties[key]
      return nil if not prop or not prop.get
      prop.get self

    __newindex: (key, value) =>
      prop = properties[key]
      if prop
        if prop.set
          prop.set self, value
        else
          error 'Attempt to set read-only property "' .. key .. '"', 1
      else
        rawset self, key, value
  }
  lookup_tables[base] = t
  t

class PropertyObject
  new: =>
    setmetatable self, property_lookup_table(self)

  property: (cls, tbl) ->
    cls.__base.__properties = cls.__base.__properties or {}
    cls.__base.__properties[k] = v for k,v in pairs tbl

return PropertyObject
