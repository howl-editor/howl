-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

require 'ljglibs.gio.input_stream'
ffi = require 'ffi'
core = require 'ljglibs.core'
{:ref_ptr} = require 'ljglibs.gobject'

C = ffi.C

core.define 'GUnixInputStream < GInputStream', {
  properties: {
    fd: 'gint'
    close_fd: 'gboolean'
  }

}, (t, fd, close_fd = true) ->
  ref_ptr C.g_unix_input_stream_new fd, close_fd
