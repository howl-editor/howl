-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
require 'ljglibs.gdk.window'
require 'ljglibs.gobject.object'
require 'ljglibs.cairo.context'
require 'ljglibs.pango.context'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

C, ffi_cast, ffi_string = ffi.C, ffi.cast, ffi.string
ref_ptr, gc_ptr, signal = gobject.ref_ptr, gobject.gc_ptr, gobject.signal
widget_t = ffi.typeof 'GtkWidget *'
cairo_t = ffi.typeof 'cairo_t *'
controller_t = ffi.typeof 'GtkEventController *'
{:pack, :unpack, insert: append} = table

to_w = (o) -> ffi_cast widget_t, o

jit.off true, true

core.define 'GtkWidget < GObject', {
  properties: {
    can_focus: 'gboolean'
    can_target: 'gboolean'
    -- NYI: css_classes: 'string[]'
    cursor: 'GdkCursor *'
    focus_on_click: 'gboolean'
    focusable: 'gboolean'
    halign: 'GtkAlign'
    has_default: 'gboolean'
    has_focus: 'gboolean'
    has_tooltip: 'gboolean'
    height_request: 'gint'
    hexpand: 'gboolean'
    hexpand_set: 'gboolean'
    margin_bottom: 'gint'
    margin_end: 'gint'
    margin_start: 'gint'
    margin_top: 'gint'
    name: 'gchar*'
    opacity: 'gdouble'
    -- NYI: overflow
    parent: 'GtkWidget*'
    receives_default: 'gboolean'
    -- NYI: root
    scale_factor: 'int'
    sensitive: 'gboolean'
    tooltip_markup: 'gchar*'
    tooltip_text: 'gchar*'
    valign: 'GtkAlign'
    vexpand: 'gboolean'
    vexpand_set: 'gboolean'
    visible: 'gboolean'
    width_request: 'gint'

    css_classes: {
      get: =>
        classes = C.gtk_widget_get_css_classes @
        t = {}
        i = 0
        while classes[i] != nil
          append t, ffi_string(classes[i])
          i += 1

        C.g_strfreev classes
        t

      set: (classes) =>
        a = ffi.new "const char *[?]", #classes + 1
        for i, c in ipairs classes
          a[i - 1] = c
          print ffi.string(a[i - 1])
        a[#classes] = nil
        C.gtk_widget_set_css_classes @, a
    }

    -- Added properties
    in_destruction: => C.gtk_widget_in_destruction(@) != 0
    style_context: => ref_ptr C.gtk_widget_get_style_context @
    pango_context: => C.gtk_widget_get_pango_context @
    allocated_width: => C.gtk_widget_get_allocated_width @
    allocated_height: => C.gtk_widget_get_allocated_height @

    first_child: => @get_first_child!
    last_child: => @get_last_child!
    next_sibling: => @get_next_sibling!
    prev_sibling: => @get_prev_sibling!
    focus_child: => @get_focus_child!

    children: =>
      r = {}
      child = @first_child
      while child
        append r, child
        child = child.next_sibling
      r
  }

  realize: => C.gtk_widget_realize @
  show: => C.gtk_widget_show @
  hide: => C.gtk_widget_hide @
  grab_focus: => C.gtk_widget_grab_focus @

  get_first_child: =>
    c = C.gtk_widget_get_first_child @
    c != nil and c or nil

  get_last_child: =>
    c = C.gtk_widget_get_last_child @
    c != nil and c or nil

  get_next_sibling: =>
    w = C.gtk_widget_get_next_sibling @
    w != nil and w or nil

  get_prev_sibling: =>
    w = C.gtk_widget_get_prev_sibling @
    w != nil and w or nil

  get_focus_child: =>
    w = C.gtk_widget_get_focus_child @
    w != nil and w or nil

  translate_coordinates: (dest_widget, src_x, src_y) =>
    ret = ffi.new 'gint [2]'
    status = C.gtk_widget_translate_coordinates @, to_w(dest_widget), src_x, src_y, ret, ret + 1
    error "Failed to translate coordinates" if status == 0
    ret[0], ret[1]

  set_size_request: (width, height) => C.gtk_widget_set_size_request @, width, height

  create_pango_context: => gc_ptr C.gtk_widget_create_pango_context @

  add_controller: (controller) =>
    C.gtk_widget_add_controller @, ffi_cast(controller_t,  controller)

  queue_allocate: => C.gtk_widget_queue_allocate @

  queue_resize: => C.gtk_widget_queue_resize @

  queue_draw: => C.gtk_widget_queue_draw @

  queue_draw_area: (x, y, width, height) =>
    C.gtk_widget_queue_draw_area @, x, y, width, height

  on_draw: (handler, ...) =>
    error "GTK4: no draw signal"

  add: (child) =>
    error "GTK4 deprecation: no add for container widget"
    @child = child

}
