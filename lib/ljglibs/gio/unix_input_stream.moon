-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

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
