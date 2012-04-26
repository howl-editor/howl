new = (options = {}) ->
  spy =
    called: false
    reads: {}
    writes: {}

  setmetatable spy,
    __call: ->
      spy.called = true
      options.with_return

    __index: (t,k) ->
      table.insert spy.reads, k
      nil

    __newindex: (t,k,v) ->
      spy.writes[k] = v
  spy

return setmetatable {}, __call: (_, options) -> new options
