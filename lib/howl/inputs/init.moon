inputs = {}

register = (name, func) ->
  error 'Missing parameter `name` for parameter', 2 if not name
  error 'Missing parameter `func` for parameter', 2 if not func

  inputs[name] = func

unregister = (name) ->
  inputs[name] = nil

return setmetatable { :register, :unregister }, {
  __index: (key) => inputs[key]
  __pairs: => (_, index) -> return next inputs, index
}
