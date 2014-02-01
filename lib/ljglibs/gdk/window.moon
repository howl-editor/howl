-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'

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
  }
}
