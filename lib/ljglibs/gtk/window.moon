-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
glib = require 'ljglibs.glib'
core = require 'ljglibs.core'
require 'ljglibs.gtk.bin'

C, ffi_string = ffi.C, ffi.string
catch_error = glib.catch_error
optional = core.optional

core.define 'GtkWindow < GtkBin', {
  constants: {
    prefix: 'GTK_WINDOW_'

    -- GtkWindowType
    'TOPLEVEL',
    'POPUP'
  }

  properties: {
    title:
      get: => ffi_string C.gtk_window_get_title @
      set: (title) => C.gtk_window_set_title @, title

    window_type: => C.gtk_window_get_window_type @

    focus:
      get: => optional C.gtk_window_get_focus @
      set: (focus) => C.gtk_window_set_focus @, focus
  }

  new: (type = C.GTK_WINDOW_TOPLEVEL) -> C.gtk_window_new!

  set_default_size: (width, height) => C.gtk_window_set_default_size @, width, height
  resize: (width, height) => C.gtk_window_resize @, width, height
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
