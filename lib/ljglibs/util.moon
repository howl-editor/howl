-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
bit = require 'bit'
Gdk = require 'ljglibs.gdk'
require 'ljglibs.cdefs.glib'

C, ffi_cast, ffi_string = ffi.C, ffi.cast, ffi.string
band = bit.band
gchar_arr = ffi.typeof 'gchar [?]'

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
  parse_key_event: (key_event) ->
    key_event = ffi_cast('GdkEventKey *', key_event)
    event = {
      shift: band(key_event.state, C.GDK_SHIFT_MASK) != 0,
      control: band(key_event.state, C.GDK_CONTROL_MASK) != 0,
      alt: band(key_event.state, C.GDK_MOD1_MASK) != 0,
      super: band(key_event.state, C.GDK_SUPER_MASK) != 0,
      meta: band(key_event.state, C.GDK_META_MASK) != 0,
    }
    explain_key_code key_event.keyval, event
    event

}
