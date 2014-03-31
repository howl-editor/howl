-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import mode from howl
import Matcher from howl.util
append = table.insert

load_matcher = ->
  modes = moon.copy mode.names
  table.sort modes
  Matcher modes

class ModeInput
  should_complete: -> true
  close_on_cancel: -> true

  complete: (text) =>
    @matcher = load_matcher! unless @matcher
    completion_options = title: 'Modes'
    return self.matcher(text), completion_options

  value_for: (text) =>
    mode.by_name text

howl.inputs.register {
  name: 'mode',
  description: 'Returns a mode instance'
  factory: ModeInput
}

return ModeInput
