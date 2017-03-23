-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

interactions = {}  -- registry

register = (spec) ->
  for field in *{'name', 'description'}
    error 'Missing field for command: "' .. field .. '"' if not spec[field]

  if not (spec.factory or spec.handler) or (spec.factory and spec.handler)
    error 'One of "factory" or "handler" required'

  interactions[spec.name] = moon.copy spec

unregister = (name) ->
  interactions[name] = nil

sequence = (order, def) ->
    for name in *order
      error "#{name} not found in def" unless def[name]

    state = {}
    pos = 1

    while true
      def.update state if def.update

      current = order[pos]
      if current
        result = def[current](state)
        return nil unless result

        if result.back
            pos -= 1
            state[order[pos]] = nil
        else
            state[current] = result
            pos += 1
        continue
      else
        if def.finish
          return def.finish state
        return state

get = (name) -> interactions[name]

return setmetatable {:register, :unregister, :get, :sequence}, {
  __index: (interaction_name) =>
    spec = get(interaction_name)
    return if not spec
    (...) -> howl.app.window.command_line\run spec, ...
}
