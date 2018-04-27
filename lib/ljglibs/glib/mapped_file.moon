-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.glib'
core = require 'ljglibs.core'
{ :catch_error } = require 'ljglibs.glib'

C, ffi_gc = ffi.C, ffi.gc

core.define 'GMappedFile', {
  properties: {
    length: => tonumber C.g_mapped_file_get_length @
    contents: => C.g_mapped_file_get_contents @
  }

  new: (path, writable = false) ->
    ffi_gc catch_error(C.g_mapped_file_new, path, writable), C.g_mapped_file_unref

  unref: =>
    ffi_gc @, nil
    C.g_mapped_file_unref @

  meta: {
    __len: => @.length
  }

}, (t, ...) -> t.new ...
