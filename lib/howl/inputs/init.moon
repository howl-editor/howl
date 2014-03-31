-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

inputs = {}

register = (spec) ->
  for field in *{'name', 'description', 'factory'}
    error 'Missing field for input: "' .. field .. '"' if not spec[field]

  inputs[spec.name] = setmetatable spec, __call: (input, ...) -> input.factory ...

unregister = (name) ->
  inputs[name] = nil

names = -> [name for name in pairs inputs]

return setmetatable { :register, :unregister, :names }, {
  __index: (key) => inputs[key]
  __pairs: => (_, index) -> return next inputs, index
}
