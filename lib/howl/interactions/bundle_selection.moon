-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import bundle, interact from howl

bundle_desc = (name) ->
  desc = _G.bundles[name].info.description
  desc\match '^%s*([^\r\n.]+)'

interact.register
  name: 'select_loaded_bundle'
  description: 'Selection list for loaded bundles'
  handler: (opts={}) ->
    opts = moon.copy opts
    with opts
      .title or= 'Loaded bundles'
      .items = [ { name, bundle_desc(name) } for name in pairs _G.bundles ]
    selected = interact.select opts

    if selected
      return selected[1]

interact.register
  name: 'select_unloaded_bundle'
  description: 'Selection list for unloaded bundles'
  handler: (opts={}) ->
    opts = moon.copy opts
    with opts
      .title or= 'Unloaded bundles'
      .items = bundle.unloaded

    interact.select opts
