-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

C, cast = ffi.C, ffi.cast
gc_ptr = gobject

provider_p = ffi.typeof 'GtkStyleProvider *'

jit.off true, true

core.define 'GtkStyleContext', {

  new: -> gc_ptr C.gtk_style_context_new!

  add_provider_for_screen: (screen, provider, priority) ->
    C.gtk_style_context_add_provider_for_screen screen, cast(provider_p, provider), priority

  add_class: (cls) => C.gtk_style_context_add_class @, cls
  remove_class: (cls) => C.gtk_style_context_remove_class @, cls
  get_background_color: (state) =>
    rgba = ffi.new 'GdkRGBA'
    C.gtk_style_context_get_background_color @, state, rgba
    rgba

}, (spec) -> spec.new!
