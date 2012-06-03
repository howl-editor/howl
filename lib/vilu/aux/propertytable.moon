property_table = (properties) ->
  setmetatable {},
    __index: (t, key) ->
      prop = properties[key]
      if prop and prop.get then return prop.get t
      nil

    __newindex: (t, key, value) ->
      prop = properties[key]
      if prop
        if prop.set then prop.set t, value
        else error 'Attempt to write to a read-only property "' .. key .. '"'
      else
        rawset t, key, value

return setmetatable {}, __call: (_, properties) -> property_table properties
