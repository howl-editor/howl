-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
bit = require 'bit'
Gdk = require 'ljglibs.gdk'
require 'ljglibs.cdefs.glib'

C, ffi_string, ffi_cast = ffi.C, ffi.string, ffi.cast
band = bit.band
gchar_arr = ffi.typeof 'gchar [?]'
guint_t = ffi.typeof 'guint'
modifier_t = ffi.typeof 'GdkModifierType'

explain_key_code = (code, event) ->
  effective_code = code == 10 and Gdk.KEY_Return or code

  key_name = C.gdk_keyval_name effective_code
  if key_name != nil
    event.key_name = ffi_string(key_name)\lower!

  unicode_char = C.gdk_keyval_to_unicode code

  if unicode_char != 0
    utf8 = gchar_arr(6)
    nr_utf8 = C.g_unichar_to_utf8 unicode_char, utf8
    if nr_utf8 > 0
      event.character = ffi.string utf8, nr_utf8

  event.key_code = code

{
  construct_key_event: (keyval, state) ->
    keyval = ffi_cast guint_t, keyval
    state = ffi_cast modifier_t, state
    event = {
      shift: band(state, C.GDK_SHIFT_MASK) != 0,
      control: band(state, C.GDK_CONTROL_MASK) != 0,
      alt: band(state, C.GDK_ALT_MASK) != 0,
      super: band(state, C.GDK_SUPER_MASK) != 0,
      meta: band(state, C.GDK_META_MASK) != 0,
      lock: band(state, C.GDK_LOCK_MASK) != 0,
    }
    explain_key_code keyval, event
    event
}
