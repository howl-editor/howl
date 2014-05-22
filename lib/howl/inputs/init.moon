-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

inputs = {}

register = (spec) ->
  for field in *{'name', 'description', 'factory'}
    error 'Missing field for input: "' .. field .. '"' if not spec[field]

  inputs[spec.name] = setmetatable spec, __call: (input, ...) -> input.factory '', ...

unregister = (name) ->
  inputs[name] = nil

names = -> [name for name in pairs inputs]

read = (input, opts = {}) ->
  error 'Missing field "prompt"', 2 unless opts.prompt

  if type(input) == 'string'
    factory = inputs[input]
    error "Unknown input '#{input}'", 2 unless factory
    input = factory!

  howl.app.window.readline\read opts.prompt, input

return setmetatable { :register, :unregister, :names, :read }, {
  __index: (key) => inputs[key]
  __pairs: => (_, index) -> return next inputs, index
}
