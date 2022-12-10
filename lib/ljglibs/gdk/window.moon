-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- GTK4: Remove

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gdk.cursor'
require 'ljglibs.gdk.display'

ref_ptr = gobject.ref_ptr
bit_flags = core.bit_flags

C = ffi.C

core.define 'GdkWindow', {
  constants: {
    prefix: 'GDK_WINDOW_'

    'STATE_WITHDRAWN',
    'STATE_ICONIFIED',
    'STATE_MAXIMIZED',
    'STATE_STICKY',
    'STATE_FULLSCREEN',
    'STATE_ABOVE',
    'STATE_BELOW',
    'STATE_FOCUSED',
    'STATE_TILED',
  }

  properties: {
    state: => bit_flags @, 'STATE_', C.gdk_window_get_state @
    events: {
      get: => C.gdk_window_get_events @
      set: (events) => C.gdk_window_set_events @, events
    }
    cursor: {
      get: => C.gdk_window_get_cursor @
      set: (cursor) => C.gdk_window_set_cursor @,cursor
    }

    display: => ref_ptr C.gdk_window_get_display @
    scale_factor: => tonumber C.gdk_window_get_scale_factor @
  }

  get_position: =>
    ret = ffi.new 'gint [2]'
    C.gdk_window_get_position @, ret, ret + 1
    ret[0], ret[1]

  set_opacity: (opacity) =>
    C.gdk_window_set_opacity @, opacity
}
