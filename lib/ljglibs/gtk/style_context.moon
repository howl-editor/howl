-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'

C, cast = ffi.C, ffi.cast

provider_p = ffi.typeof 'GtkStyleProvider *'

jit.off true, true

{
  add_provider_for_display: (display, provider, priority) ->
    C.gtk_style_context_add_provider_for_display display, cast(provider_p, provider), priority

}
