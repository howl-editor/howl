-- Copyright 2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'

require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

gc_ptr = gobject.gc_ptr
C = ffi.C

jit.off true, true

core.define 'GtkPopover < GtkWidget', {
  properties: {
    autohide: 'gboolean'
    cascade_popdown: 'gboolean'
    child: 'GtkWidget *'
    has_arrow: 'gboolean'
    position: 'GtkPositionType'
    default_widget: 'GtkWidget*'

    pointing_to: {
      get: =>
        rect = ffi.new('GdkRectangle[1]')
        filled = C.gtk_popover_get_pointing_to @, rect
        return nil unless filled
        {
          x: rect[0].x,
          y: rect[0].y,
          width: rect[0].width,
          height: rect[0].height,
        }

      set: (rect) =>
        g_rect = ffi.new('GdkRectangle[1]')
        g_rect[0].x = rect.x
        g_rect[0].y = rect.y
        g_rect[0].width = rect.width
        g_rect[0].height = rect.height
        C.gtk_popover_set_pointing_to @, g_rect
    }
  }


  new: -> gc_ptr C.gtk_popover_new!
  popup: => C.gtk_popover_popup @
  popdown: => C.gtk_popover_popdown @
  set_offset: (x, y) => C.gtk_popover_set_offset @, x, y
  present: => C.gtk_popover_present @

}, (spec, ...) -> spec.new ...
