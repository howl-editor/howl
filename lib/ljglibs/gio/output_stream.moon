-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

glib = require 'ljglibs.glib'
ffi = require 'ffi'
core = require 'ljglibs.core'

import catch_error from glib

C = ffi.C
ffi_string, ffi_new, ffi_cast = ffi.string, ffi.new, ffi.cast
buf_t = ffi.typeof 'unsigned char[?]'
const_void_p = ffi.typeof 'const void *'

core.define 'GOutputStream < GObject', {

  close: => catch_error C.g_output_stream_close, @, nil
  flush: => catch_error C.g_output_stream_flush, @, nil

  write_all: (data, count = #data) =>
    return '' if count == 0
    written = ffi_new 'gsize[1]'
    catch_error C.g_output_stream_write_all, @, ffi_cast(const_void_p, data), count, written, nil
}
