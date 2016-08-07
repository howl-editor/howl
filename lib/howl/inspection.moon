-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import PropertyTable from howl.util

inspections = {}

register = (options = {}) ->
  error 'Missing parameter `name` for inspection', 2 if not options.name
  error 'Missing parameter `factory` for inspection', 2 if not options.factory

  inspections[options.name] = options

unregister = (name) ->
  inspections[name] = nil

mod = setmetatable {
  :register,
  :unregister
  list: get: -> [c for _, c in pairs inspections]
}, {
  __index: (key) => inspections[key]
}

return PropertyTable mod
