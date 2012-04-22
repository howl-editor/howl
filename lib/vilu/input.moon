import Gdk, GLib from lgi

ffi = require 'ffi'
C = ffi.C
cbuf = ffi.new 'char[?]', 6

ffi.cdef[[
int g_unichar_to_utf8 (unsigned char c, char *outbuf);
]]

return {
  process: (buffer, event) ->
    _G.print("event.code = " .. _G.tostring(event.keyval))
    code = event.keyval
    key_name = Gdk.keyval_name code
    _G.print("key_name = " .. _G.tostring(key_name))
    unicode_char = Gdk.keyval_to_unicode code
    utf8 = nil

    if unicode_char > 0
      length = C.g_unichar_to_utf8 unicode_char, cbuf
      utf8 = ffi.string(cbuf, length)
      _G.print("utf8 = " .. _G.tostring(utf8))
}
