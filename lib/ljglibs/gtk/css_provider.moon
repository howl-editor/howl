-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.css_section'

C = ffi.C

jit.off true, true

core.define 'GtkCssProvider', {
  new: -> C.gtk_css_provider_new!

  load_from_data: (data) =>
    C.gtk_css_provider_load_from_data(@, data, #data)

  load_from_path: (path) =>
    C.gtk_css_provider_load_from_path(@, path)

  to_string: =>
    ptr = C.gtk_css_provider_to_string(@)
    s = ffi.string ptr
    C.g_free ptr
    s

}, (spec) -> spec.new!
