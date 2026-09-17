-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
glib = require 'ljglibs.glib'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

C = ffi.C
catch_error = glib.catch_error
{:ref_ptr} = gobject

jit.off true, true

core.define 'GtkWindow < GtkWidget', {
  constants: {
    prefix: 'GTK_WINDOW_'
  }

  properties: {
    application: 'GtkApplication*'
    child: 'GtkWidget*'
    decorated: 'gboolean'
    default_height: 'gint'
    default_width: 'gint'
    deletable: 'gboolean'
    destroy_with_parent: 'gboolean'
    display: 'GdkDisplay*'
    focus_visible: 'gboolean'
    focus_widget: 'GtkWidget*'
    fullscreened: 'gboolean'
    handle_menubar_accel: 'gboolean'
    hide_on_close: 'gboolean'
    icon_name: 'gchar*'
    is_active: 'gboolean'
    maximized: 'gboolean'
    mnemonics_visible: 'gboolean'
    modal: 'gboolean'
    resizable: 'gboolean'
    startup_id: 'gchar*'
    title: 'gchar*'
    titlebar: 'GtkWidget*'

    -- added properties
    focus:
      get: => ref_ptr C.gtk_window_get_focus @
      set: (focus) => C.gtk_window_set_focus @, focus
  }

  new: -> ref_ptr C.gtk_window_new!
  destroy: => C.gtk_window_destroy @

  set_default_size: (width, height) => C.gtk_window_set_default_size @, width, height

  get_default_size: =>
    sizes = ffi.new 'gint [2]'
    C.gtk_window_get_default_size @, sizes, sizes + 1
    sizes[0], sizes[1]

  fullscreen: => C.gtk_window_fullscreen @
  unfullscreen: => C.gtk_window_unfullscreen @
  maximize: => C.gtk_window_maximize @
  unmaximize: => C.gtk_window_unmaximize @

  set_default_icon_from_file: (filename) ->
    catch_error(C.gtk_window_set_default_icon_from_file, filename) != 0

}, (spec) -> spec.new!
