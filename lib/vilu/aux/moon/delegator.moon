forwarding_table = (target, base) ->
  return {
    __index: (key) =>
      val = base[key]
      return val if val
      val = target[key]
      t = type(val)
      return val if t != 'function' and t != 'userdata'
      return (self, ...) ->
        val(target, ...)

    __newindex: (key, value) =>
      target[key] = value
  }

class Delegator
  new: (target) =>
    setmetatable self, forwarding_table(target, getmetatable(self))

return Delegator
