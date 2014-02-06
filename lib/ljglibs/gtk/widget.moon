-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
require 'ljglibs.gdk.window'
require 'ljglibs.gobject.object'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

C, ffi_cast = ffi.C, ffi.cast
ref_ptr = gobject.ref_ptr
widget_t = ffi.typeof 'GtkWidget *'
to_w = (o) -> ffi_cast widget_t, o

core.define 'GtkWidget < GObject', {
  properties: {
    app_paintable: 'gboolean'
    can_default: 'gboolean'
    can_focus: 'gboolean'
    composite_child: 'gboolean'
    double_buffered: 'gboolean'
    events: 'GdkEventMask'
    expand: 'gboolean'
    halign: 'GtkAlign'
    has_default: 'gboolean'
    has_focus: 'gboolean'
    has_tooltip: 'gboolean'
    height_request: 'gint'
    hexpand: 'gboolean'
    hexpand_set: 'gboolean'
    is_focus: 'gboolean'
    margin: 'gint'
    margin_bottom: 'gint'
    margin_left: 'gint'
    margin_right: 'gint'
    margin_top: 'gint'
    name: 'gchar*'
    no_show_all: 'gboolean'
    opacity: 'gdouble'
    parent: 'GtkContainer*'
    receives_default: 'gboolean'
    sensitive: 'gboolean'
    style: 'GtkStyle*'
    tooltip_markup: 'gchar*'
    tooltip_text: 'gchar*'
    valign: 'GtkAlign'
    vexpand: 'gboolean'
    vexpand_set: 'gboolean'
    visible: 'gboolean'
    width_request: 'gint'
    window: 'GdkWindow*'

    -- added properties
    screen: => ref_ptr C.gtk_widget_get_screen @
    style_context: => ref_ptr C.gtk_widget_get_style_context @
    allocated_width: => C.gtk_widget_get_allocated_width @
    allocated_height: => C.gtk_widget_get_allocated_height @
    toplevel: => ref_ptr C.gtk_widget_get_toplevel @
   }

  realize: => C.gtk_widget_realize @
  show: => C.gtk_widget_show @
  show_all: => C.gtk_widget_show_all @
  hide: => C.gtk_widget_hide @
  grab_focus: => C.gtk_widget_grab_focus @
  destroy: => C.gtk_widget_destroy @

  translate_coordinates: (dest_widget, src_x, src_y) =>
    ret = ffi.new 'gint [2]'
    status = C.gtk_widget_translate_coordinates @, to_w(dest_widget), src_x, src_y, ret, ret + 1
    error "Failed to translate coordinates" if status == 0
    ret[0], ret[1]

  set_size_request: (width, height) => C.gtk_widget_set_size_request @, width, height

  override_background_color: (state, color) =>
    C.gtk_widget_override_background_color @, state, color
}
