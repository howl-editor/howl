-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
core = require 'ljglibs.core'
require 'ljglibs.cdefs.gio'
require 'ljglibs.gio.socket_listener'
{:gc_ptr} = require 'ljglibs.gobject'

C = ffi.C

-- Accepts connections on the GLib main loop, which is what lets a spec run a
-- real HTTP server in-process without threads or an external listener.
-- Connect to the 'incoming' signal with \connect_for.
core.define 'GSocketService < GSocketListener', {

  properties: {
    is_active: => C.g_socket_service_is_active(@) != 0
  }

  start: => C.g_socket_service_start @
  stop: => C.g_socket_service_stop @

}, (def) -> gc_ptr C.g_socket_service_new!
