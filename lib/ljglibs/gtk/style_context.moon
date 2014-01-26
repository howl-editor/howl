-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'

C = ffi.C
cast = ffi.cast

provider_p = ffi.typeof 'GtkStyleProvider *'

core.define 'GtkStyleContext', {
  add_provider_for_screen: (screen, provider, priority) ->
    C.gtk_style_context_add_provider_for_screen screen, cast(provider_p, provider), priority
}
