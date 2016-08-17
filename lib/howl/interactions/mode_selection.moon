-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact, mode from howl

interact.register
  name: 'select_mode'
  description: 'Selection list for modes'
  handler: (opts={}) ->
    selection = nil
    if opts.buffer
      selection = opts.buffer.mode.name

    selected = interact.select
      title: opts.title or 'Mode'
      items: mode.names
      :selection

    return unless selected
    return mode.by_name selected.selection
