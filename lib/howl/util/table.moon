type = type

local delegate_to

delegating_mt = {
  __index: (t, k) ->
    o_v = t.overlay[k]
    b_v = t.base[k]

    if o_v
      if type(o_v) != 'table' or not b_v or type(b_v) != 'table'
        return o_v

      return delegate_to b_v, o_v

    b_v

  __pairs: (t) ->
    joint = {}
    joint[k] = v for k, v in pairs t.base
    joint[k] = v for k, v in pairs t.overlay
    pairs joint

}

delegate_to = (base, overlay) ->
  setmetatable {:base, :overlay}, delegating_mt

:delegate_to
