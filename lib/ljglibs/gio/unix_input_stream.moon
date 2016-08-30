-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

require 'ljglibs.gio.input_stream'
ffi = require 'ffi'
core = require 'ljglibs.core'

C = ffi.C

release = (p) ->
  C.g_input_stream_close, p, nil
  C.g_object_unref(p)

core.define 'GUnixInputStream < GInputStream', {
  properties: {
    fd: 'gint'
    close_fd: 'gboolean'
  }

}, (t, fd, close_fd = true) ->
  ffi.gc C.g_unix_input_stream_new(fd, close_fd), release
