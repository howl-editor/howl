-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'
import catch_error from glib

C = ffi.C

jit.off true, true

core.define 'GtkCssProvider', {
  load_from_data: (data) =>
    catch_error(C.gtk_css_provider_load_from_data, @, data, #data) != 0

}, -> C.gtk_css_provider_new!
