-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
ffi = require 'ffi'
core = require 'ljglibs.core'
require 'ljglibs.cdefs.gio'
require 'ljglibs.gio.socket_connection'

{:catch_error} = glib
C = ffi.C

core.define 'GSocketListener < GObject', {

  -- Binds an ephemeral port on all interfaces and returns it. Specs use this to
  -- get a loopback server without hardcoding a port that might be in use.
  add_any_inet_port: (source_object) =>
    tonumber catch_error C.g_socket_listener_add_any_inet_port, @, source_object

  close: => C.g_socket_listener_close @
}
