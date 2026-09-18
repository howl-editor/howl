-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
ffi = require 'ffi'
core = require 'ljglibs.core'
gio = require 'ljglibs.gio'
callbacks = require 'ljglibs.callbacks'
jit = require 'jit'
require 'ljglibs.cdefs.gio'
require 'ljglibs.gio.socket_connection'
{:gc_ptr} = require 'ljglibs.gobject'

{:get_error} = glib
C = ffi.C

SocketClient = core.define 'GSocketClient < GObject', {

  properties: {
    tls: {
      get: => C.g_socket_client_get_tls(@) != 0
      set: (v) => C.g_socket_client_set_tls @, v and 1 or 0
    }

    -- seconds; covers the connect phase and blocking ops, but not our async
    -- reads - those need a cancellable, see ljglibs.gio.cancellable
    timeout: {
      get: => tonumber C.g_socket_client_get_timeout(@)
      set: (v) => C.g_socket_client_set_timeout @, v
    }

    enable_proxy: {
      get: => C.g_socket_client_get_enable_proxy(@) != 0
      set: (v) => C.g_socket_client_set_enable_proxy @, v and 1 or 0
    }
  }

  -- Connecting by URI rather than by host is deliberate: it attaches the scheme
  -- to the connectable, which is what GProxyResolver needs to pick the right
  -- proxy and what supplies the TLS server identity (SNI and hostname
  -- verification). Connecting to a pre-resolved IP would silently disable that.
  connect_to_uri_async: (uri, default_port, cancellable, callback) =>
    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      status, ret, err_code, domain = get_error C.g_socket_client_connect_to_uri_finish, @, res
      if not status
        callback false, ret, err_code, domain
      else
        callback true, gc_ptr ret

    handle = callbacks.register handler, 'socket-client-connect'
    C.g_socket_client_connect_to_uri_async @, uri, default_port, cancellable,
      gio.async_ready_callback, callbacks.cast_arg(handle.id)
}, (def) -> gc_ptr C.g_socket_client_new!

-- HTTPS is unavailable without a TLS backend (glib-networking). Checking up
-- front turns a baffling connection error into an actionable message.
SocketClient.tls_supported = ->
  backend = C.g_tls_backend_get_default!
  return false if backend == nil
  C.g_tls_backend_supports_tls(backend) != 0

jit.off SocketClient.connect_to_uri_async

SocketClient
