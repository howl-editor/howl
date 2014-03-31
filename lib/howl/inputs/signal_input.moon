-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import signal from howl
import Matcher from howl.util
append = table.insert

load_matcher = ->
  signals = {}
  for name, def in pairs signal.all
    append signals, { name, def.description\match '[^\n.]*' }
  table.sort signals, (a, b) -> a[1] < b[1]
  Matcher signals

class SignalInput
  should_complete: -> true
  close_on_cancel: -> true

  complete: (text) =>
    @matcher = load_matcher! unless @matcher
    completion_options = title: 'Signals'
    return self.matcher(text), completion_options

howl.inputs.register {
  name: 'signal',
  description: 'Returns the name of a registered signal'
  factory: SignalInput
}

return SignalInput
