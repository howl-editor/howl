import rawget, rawset, ipairs from _G

is_ustring = u.is_instance

(t = {}) ->
  setmetatable t,
    __index: (t, k) ->
      k = tostring(k) if is_ustring k
      rawget t, k

    __newindex: (t, k, v) ->
      k = tostring(k) if is_ustring k
      rawset t, k, v
