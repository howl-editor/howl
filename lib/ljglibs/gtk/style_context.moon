-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

C, cast = ffi.C, ffi.cast
gc_ptr = gobject

provider_p = ffi.typeof 'GtkStyleProvider *'

core.define 'GtkStyleContext', {

  new: -> gc_ptr C.gtk_style_context_new!

  add_provider_for_screen: (screen, provider, priority) ->
    C.gtk_style_context_add_provider_for_screen screen, cast(provider_p, provider), priority

  add_class: (cls) => C.gtk_style_context_add_class @, cls
  remove_class: (cls) => C.gtk_style_context_remove_class @, cls

}, (spec) -> spec.new!
