-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import dispatch from howl

interactions = {}  -- registry

register = (spec) ->
  for field in *{'name', 'description'}
    error 'Missing field for command: "' .. field .. '"' if not spec[field]

  if not (spec.factory or spec.handler) or (spec.factory and spec.handler)
    error 'One of "factory" or "handler" required'

  interactions[spec.name] = moon.copy spec

unregister = (name) ->
  interactions[name] = nil

get = (name) -> interactions[name]

return setmetatable {:register, :unregister, :get}, {
  __index: (interaction_name) =>
    spec = get(interaction_name)
    return if not spec
    (...) -> howl.app.window.command_line\run spec, ...
}
