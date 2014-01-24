-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

require 'ljglibs.cdefs.glib'
ffi = require 'ffi'
C, ffi_string = ffi.C, ffi.string

return {
  gint: ffi.typeof 'gint'
  GError: ffi.typeof 'GError'

  g_string: (ptr) ->
    return nil if ptr == nil
    s = ffi_string ptr
    C.g_free ptr
    s

  gchar_arr: ffi.typeof 'gchar[?]'

  GDK_KEY_Return: 0xff0d
}
