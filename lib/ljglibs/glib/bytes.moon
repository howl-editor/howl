-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.glib'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'
import g_string, catch_error from glib

C, ffi_string, ffi_gc, ffi_cast = ffi.C, ffi.string, ffi.gc, ffi.cast
gconstpointer_t = ffi.typeof 'gconstpointer'
to_gcp = (v) -> ffi_cast gconstpointer_t, v

core.define 'GBytes', {
  properties: {
    size: => tonumber C.g_bytes_get_size @
    data: =>
      size = @size
      ffi.string(C.g_bytes_get_data(@, nil), size)
  }

  ref: (bytes) -> C.g_bytes_ref bytes
  unref: (bytes) -> C.g_bytes_ref bytes
  gc_ptr: (bytes) ->
    return nil if bytes == nil
    ffi_gc(bytes, C.g_bytes_unref)

  meta: {
    __len: => @.size
  }

}, (t, data, size = #data) ->
  t.gc_ptr C.g_bytes_new(to_gcp(data), size)
