-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import inputs from howl
import Matcher from howl.util
append = table.insert

load_matcher = ->
  candidates = {}
  for name in *inputs.names!
    append candidates, { name, inputs[name].description\match '[^\n.]*' }
  table.sort candidates, (a, b) -> a[1] < b[1]
  Matcher candidates

class InputInput
  should_complete: -> true
  close_on_cancel: -> true

  complete: (text) =>
    @matcher = load_matcher! unless @matcher
    completion_options = title: 'Inputs'
    return self.matcher(text), completion_options

howl.inputs.register {
  name: 'input',
  description: 'Returns the name of a registered input'
  factory: InputInput
}

return InputInput
