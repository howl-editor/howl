-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

ffi_string = ffi.string
gc_ptr = gobject.gc_ptr

C = ffi.C

jit.off true, true

core.define 'GtkLabel < GtkWidget', {
  properties: {
    angle: 'gdouble'
    cursor_position: 'gint'
    ellipsize: 'PangoEllipsizeMode'
    justify: 'GtkJustification'
    label: 'gchar*'
    lines: 'gint'
    max_width_chars: 'gint'
    mnemonic_keyval: 'guint'
    mnemonic_widget: 'GtkWidget*'
    pattern: 'gchar*'
    selectable: 'gboolean'
    selection_bound: 'gint'
    single_line_mode: 'gboolean'
    track_visited_links: 'gboolean'
    use_markup: 'gboolean'
    use_underline: 'gboolean'
    width_chars: 'gint'
    wrap: 'gboolean'

    text:
      get: => ffi_string C.gtk_label_get_text @
      set: (text) =>  C.gtk_label_set_text @, text
  }

  new: (str) ->
    gc_ptr C.gtk_label_new str

  get_layout: =>
    C.gtk_label_get_layout @

}, (spec, ...) -> spec.new ...
