-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
glib = require 'ljglibs.glib'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.bin'

C, ffi_string = ffi.C, ffi.string
catch_error = glib.catch_error
ref_ptr = gobject.ref_ptr

core.define 'GtkWindow < GtkBin', {
  constants: {
    prefix: 'GTK_WINDOW_'

    -- GtkWindowType
    'TOPLEVEL',
    'POPUP'
  }

  properties: {
    accept_focus: 'gboolean'
    application: 'GtkApplication*'
    decorated: 'gboolean'
    default_height: 'gint'
    default_width: 'gint'
    deletable: 'gboolean'
    destroy_with_parent: 'gboolean'
    focus_on_map: 'gboolean'
    focus_visible: 'gboolean'
    gravity: 'GdkGravity'
    has_resize_grip: 'gboolean'
    has_toplevel_focus: 'gboolean'
    icon: 'GdkPixbuf*'
    icon_name: 'gchar*'
    is_active: 'gboolean'
    mnemonics_visible: 'gboolean'
    modal: 'gboolean'
    opacity: 'gdouble'
    resizable: 'gboolean'
    resize_grip_visible: 'gboolean'
    role: 'gchar*'
    screen: 'GdkScreen*'
    skip_pager_hint: 'gboolean'
    skip_taskbar_hint: 'gboolean'
    startup_id: 'gchar*'
    title: 'gchar*'
    transient_for: 'GtkWindow*'
    type: 'GtkWindowType'
    type_hint: 'GdkWindowTypeHint'
    urgency_hint: 'gboolean'
    window_position: 'GtkWindowPosition'

    -- added properties
    window_type: => C.gtk_window_get_window_type @

    focus:
      get: => ref_ptr C.gtk_window_get_focus @
      set: (focus) => C.gtk_window_set_focus @, focus
  }

  new: (type = C.GTK_WINDOW_TOPLEVEL) -> C.gtk_window_new type

  set_default_size: (width, height) => C.gtk_window_set_default_size @, width, height
  resize: (width, height) => C.gtk_window_resize @, width, height
  move: (x, y) => C.gtk_window_move @, x, y
  fullscreen: => C.gtk_window_fullscreen @
  unfullscreen: => C.gtk_window_unfullscreen @
  maximize: => C.gtk_window_maximize @
  unmaximize: => C.gtk_window_unmaximize @

  get_size: =>
    sizes = ffi.new 'gint [2]'
    C.gtk_window_get_size @, sizes, size + 1
    sizes[0], sizes[1]

  set_default_icon_from_file: (filename) ->
    catch_error(C.gtk_window_set_default_icon_from_file, filename) != 0

}, (spec, type) -> spec.new type
