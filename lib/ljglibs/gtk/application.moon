-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gio.application'
import gc_ptr from gobject

C = ffi.C

jit.off true

core.define 'GtkApplication < GApplication', {

  add_window: (window) => C.gtk_application_add_window @, window
  remove_window: (window) => C.gtk_application_remove_window @, window

}, (t, application_id, flags) ->
  gc_ptr(C.gtk_application_new application_id, flags)
