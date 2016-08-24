-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

require 'ljglibs.gio.output_stream'
ffi = require 'ffi'
core = require 'ljglibs.core'
{:ref_ptr} = require 'ljglibs.gobject'

C = ffi.C

release = (p) ->
  C.g_output_stream_close, p, nil
  C.g_object_unref(p)

core.define 'GWin32OutputStream < GOutputStream', {
  properties: {
    handle: 'void*'
    close_handle: 'gboolean'
  }

}, (t, handle, close_handle = true) ->
  ffi.gc C.g_win32_output_stream_new(handle, close_handle), release
