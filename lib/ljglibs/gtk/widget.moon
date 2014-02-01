-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
require 'ljglibs.gdk.window'
require 'ljglibs.gobject.object'
core = require 'ljglibs.core'

optional = core.optional

C = ffi.C

core.define 'GtkWidget < GObject', {
  properties: {
    style_context: => C.gtk_widget_get_style_context @
    window: => optional C.gtk_widget_get_window @
    allocated_width: => C.gtk_widget_get_allocated_width @
    allocated_height: => C.gtk_widget_get_allocated_height @
  }

  realize: => C.gtk_widget_realize @
  show: => C.gtk_widget_show @
  show_all: => C.gtk_widget_show_all @
  hide: => C.gtk_widget_hide @
  grab_focus: => C.gtk_widget_grab_focus @
  destroy: => C.gtk_widget_destroy @

  override_background_color: (state, color) =>
    C.gtk_widget_override_background_color @, state, color
}
