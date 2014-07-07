{
  define_class: (base, meta = {}) ->
    props = base.properties

    meta.__index = (o, k) ->
      m = base[k]
      return m if m
      p = props[k]
      p = p.get if type(p) == 'table'
      p and p o

    meta.__newindex = (o, k, ...) ->
      p = props[k]
      p = p.set if p
      if p
        p o, ...
      else
        rawset o, k, ...

    setmetatable {}, {
      __call: (t, ...) ->
        o = setmetatable {}, meta
        if base.new
          base.new o, ...
        o
    }
}
