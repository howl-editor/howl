-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
glib = require 'howl.cdefs.glib'

C = ffi.C

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
