import Gdk, GLib from lgi
bytes = require 'bytes'
cbuf = bytes.new(6)

return {
  process: (buffer, event) ->
    _G.print("event.code = " .. _G.tostring(event.keyval))
    code = event.keyval
    key_name = Gdk.keyval_name code
    _G.print("key_name = " .. _G.tostring(key_name))
    unicode_char = Gdk.keyval_to_unicode code
    utf8 = nil

    if unicode_char > 0
      len = GLib.unichar_to_utf8(unicode_char, cbuf)
      utf8 = tostring(cbuf)\sub(1, len)
      _G.print("utf8 = " .. _G.tostring(utf8))
}
