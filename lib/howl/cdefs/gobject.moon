-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

ffi = require 'ffi'
glib = require 'howl.cdefs.glib'

C = ffi.C

ffi.cdef [[
  typedef enum {
    G_CONNECT_AFTER = 1 << 0,
    G_CONNECT_SWAPPED = 1 << 1
  } GConnectFlags;

  typedef gsize GType;

  typedef struct {
    volatile       	guint	 in_marshal : 1;
    volatile       	guint	 is_invalid : 1;
  } GClosure;

  typedef void  (*GClosureNotify) (gpointer data, GClosure *closure);

  gulong g_signal_connect_object(gpointer instance,
                                 const gchar *detailed_signal,
                                 GCallback c_handler,
                                 gpointer gobject,
                                 GConnectFlags connect_flags);

  gulong g_signal_connect_data(gpointer instance,
                               const gchar *detailed_signal,
                               GCallback c_handler,
                               gpointer data,
                               GClosureNotify destroy_data,
                               GConnectFlags connect_flags);
]]

callback3 = (handler) ->
  ffi.cast('GCallback', ffi.cast('GCallback3', handler))

callback4 = (handler) ->
  ffi.cast('GCallback', ffi.cast('GCallback4', handler))

return {
  g_signal_connect3: (instance, signal, handler, data) ->
    C.g_signal_connect_data(instance, signal, callback3(handler), ffi.cast('gpointer', data), nil, 0)

  g_signal_connect4: (instance, signal, handler, data) ->
    C.g_signal_connect_data(instance, signal, callback4(handler), ffi.cast('gpointer', data), nil, 0)

}
