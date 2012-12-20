import PropertyTable from howl.aux

completions = {}

register = (options = {}) ->
  error 'Missing parameter `name` for completion', 2 if not options.name
  error 'Missing parameter `factory` for completion', 2 if not options.factory

  completions[options.name] = options

unregister = (name) ->
  completions[name] = nil

mod = setmetatable {
  :register,
  :unregister
  list: get: -> [c for _, c in pairs completions]
}, {
  __index: (key) => completions[key]
}

return PropertyTable mod
