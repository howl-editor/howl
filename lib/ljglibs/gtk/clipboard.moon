-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'

C = ffi.C

jit.off true

core.define 'GtkClipboard < GObject', {
  get: (atom) -> C.gtk_clipboard_get atom

  properties: {
    text:
      get: => @wait_for_text!
      set: (text) => @set_text text
  }

  clear: => C.gtk_clipboard_clear @
  set_text: (text) => C.gtk_clipboard_set_text @, text, #text
  wait_for_text: => glib.g_string C.gtk_clipboard_wait_for_text @
}
