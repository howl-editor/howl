-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
core = require 'ljglibs.core'
require 'ljglibs.cdefs.gio'
require 'ljglibs.gio.io_stream'

C = ffi.C

-- Thin: it exists so the cast chain resolves and so .input_stream /
-- .output_stream are inherited from GIOStream.
core.define 'GSocketConnection < GIOStream', {

  properties: {
    is_connected: => C.g_socket_connection_is_connected(@) != 0
  }
}
