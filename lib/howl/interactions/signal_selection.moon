-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact, signal from howl

get_signals_list = ->
  signals = {}
  for name, def in pairs signal.all
    table.insert signals, { name, def.description\match('[^\n.]*'), :name }
  table.sort signals, (a, b) -> a[1] < b[1]
  return signals

interact.register
  name: 'select_signal'
  description: 'Selection list for signals'
  handler: (opts={}) ->
    opts = moon.copy opts
    with opts
      .title or= 'Signals'
      .items = get_signals_list!
      .columns = { { style: 'string' }, { style: 'comment' } }

    selected = interact.select opts

    if selected
      return selected.name
