-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

forwarding_table = (target, base) ->
  return setmetatable {
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
  }, base

class Delegator
  new: (target) =>
    setmetatable self, forwarding_table(target, getmetatable(self))

return Delegator
