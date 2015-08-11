-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gio.application'
import gc_ptr from gobject

C = ffi.C

jit.off true, true

core.define 'GtkApplication < GApplication', {

  add_window: (window) => C.gtk_application_add_window @, window
  remove_window: (window) => C.gtk_application_remove_window @, window

}, (t, application_id, flags) ->
  gc_ptr(C.gtk_application_new application_id, flags)
