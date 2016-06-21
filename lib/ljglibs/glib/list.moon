-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.glib'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'
import g_string, catch_error from glib

C, ffi_cast = ffi.C, ffi.cast
gpointer_t = ffi.typeof 'gpointer'
to_gp = (v) -> ffi_cast gpointer_t, v

core.define 'GList', {
  properties: {
    length: => tonumber C.g_list_length @
    elements: => [v for i, v in ipairs @]
  }

  new: -> ffi.cast('GList *', nil)
  free: => C.g_list_free @
  consume: (l) -> ffi.gc l, C.g_list_free

  append: (v) => C.g_list_append @, to_gp(v)
  remove: (v) => C.g_list_remove @, to_gp(v)
  nth: (n) => C.g_list_nth @, n
  nth_data: (n) => C.g_list_nth_data @, n

  meta: {
    __len: => @.length
    __ipairs: =>
      i, l = 0, @
      ->
        return nil if l == nil
        v = l\nth_data 0
        l = l\nth 1
        i += 1
        i, v
  }

}, (t, ...) -> t.new ...
