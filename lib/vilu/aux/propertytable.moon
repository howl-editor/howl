property_table = (properties) ->
  setmetatable {},
    __index: (t, key) ->
      prop = properties[key]
      if prop
        if type(prop) == 'table' and prop.get
          return prop.get t
        else
          return prop
      nil

    __newindex: (t, key, value) ->
      prop = properties[key]
      if prop
        if prop.set
          prop.set t, value
        else if prop.get
          error 'Attempt to write to a read-only property "' .. key .. '"'
        else
          rawset t, key, value
      else
        rawset t, key, value

return setmetatable {}, __call: (_, properties) -> property_table properties
