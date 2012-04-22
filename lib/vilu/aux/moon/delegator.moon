forwarding_table = (target, base) ->
  return setmetatable {
    __index: (key) =>
      val = base[key]
      return val if val
      val = target[key]
      return nil if not val
      t = type(val)
      mt = getmetatable(val)
      return val if t != 'function' and (not mt or not mt.__call)
      return (self, ...) ->
        val(target, ...)

    __newindex: target
  }, base

class Delegator
  new: (target) =>
    setmetatable self, forwarding_table(target, getmetatable(self))

return Delegator
