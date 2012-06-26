new = (options = {}) ->
  spy =
    called: false
    reads: {}
    writes: {}

  setmetatable spy,
    __call: (_, ...) ->
      spy.called = true
      rawset spy, 'called_with', {...}
      options.with_return

    __index: (t,k) ->
      table.insert spy.reads, k
      nil

    __newindex: (t,k,v) ->
      spy.writes[k] = v
  spy

return setmetatable {}, __call: (_, options) -> new options
