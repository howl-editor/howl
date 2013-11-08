-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import bundle from howl
import Matcher from howl.util

bundle_desc = (name) ->
  desc = _G.bundles[name].info.description
  desc\match '^%s*([^\r\n.]+)'

class LoadedBundleInput
  should_complete: -> true
  close_on_cancel: -> true

  complete: (text) =>
    unless @matcher
      bundles = [ { name, bundle_desc(name) } for name in pairs _G.bundles ]
      @matcher = Matcher bundles

    completion_options = title: 'Loaded bundles'
    return self.matcher(text), completion_options

class UnloadedBundleInput
  should_complete: -> true
  close_on_cancel: -> true

  complete: (text) =>
    @matcher or= Matcher bundle.unloaded
    completion_options = title: 'Unloaded bundles'
    return self.matcher(text), completion_options

howl.inputs.register 'loaded_bundle', LoadedBundleInput
howl.inputs.register 'unloaded_bundle', UnloadedBundleInput
