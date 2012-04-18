property_lookup_table = (obj) ->
  base = getmetatable obj
  properties = base.__properties

  return {
    __index: (key) =>
      val = base[key]
      return val if val
      prop = properties[key]
      return nil if not prop or not prop.get
      prop.get obj

    __newindex: (key, value) =>
      prop = properties[key]
      if prop and prop.set
        prop.set obj, value
      else
        rawset obj, key, value
  }

class PropertyObject
  new: =>
    setmetatable self, property_lookup_table(self)

  property: (cls, tbl) ->
    cls.__base.__properties = cls.__base.__properties or {}
    cls.__base.__properties[k] = v for k,v in pairs tbl

return PropertyObject
