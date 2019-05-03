-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

interactions = {}  -- registry

register = (spec) ->
  for field in *{'name', 'description', 'handler'}
    error "Missing field for interaction '#{field}' in #{spec.name}" if not spec[field]

  interactions[spec.name] = moon.copy spec

unregister = (name) ->
  interactions[name] = nil

get = (name) -> interactions[name]

return setmetatable {:register, :unregister, :get}, {
  __index: (interaction_name) =>
    spec = get(interaction_name)
    return spec and spec.handler
}
