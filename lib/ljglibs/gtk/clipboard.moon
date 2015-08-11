-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'

C = ffi.C

jit.off true, true

core.define 'GtkClipboard < GObject', {
  get: (atom) -> C.gtk_clipboard_get atom

  properties: {
    text:
      get: => @wait_for_text!
      set: (text) => @set_text text
  }

  clear: => C.gtk_clipboard_clear @
  store: => C.gtk_clipboard_store @
  set_text: (text) => C.gtk_clipboard_set_text @, text, #text
  wait_for_text: => glib.g_string C.gtk_clipboard_wait_for_text @

  set_can_store: (targets) =>
    nr_targets = targets and #targets or 0
    if nr_targets > 0
      t = ffi.new 'GtkTargetEntry[?]', nr_targets
      for i = 1, nr_targets
        t[i - 1] = targets[i]
      targets = t

    C.gtk_clipboard_set_can_store @, targets, nr_targets
}
