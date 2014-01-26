-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'
import catch_error from glib

C = ffi.C

core.define 'GtkCssProvider', {
  load_from_data: (data) =>
    catch_error(C.gtk_css_provider_load_from_data, @, data, #data) != 0

}, -> C.gtk_css_provider_new!
