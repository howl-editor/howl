import Gtk from lgi
import Scintilla from vilu
import PropertyObject from vilu.aux.moon
import style from vilu.ui

input_process = vilu.input.process

class TextView extends PropertyObject

  new: (buffer) =>
    error('Missing argument #1 (buffer)', 2) if not buffer
    super!

    @sci = Scintilla!
    style.define_styles @sci
    @sci.on_keypress = self\on_keypress
    @buffer = buffer
    self\_set_appearance!

    getmetatable(self).__to_gobject = => @sci\get_gobject!

  self\property buffer:
    get: => @_buf
    set: (buffer) =>
      if @_buf
        @_buf\remove_view_ref self

      @_buf = buffer
      @sci\set_doc_pointer(buffer.doc)
      @sci.on_style_needed = buffer\lex
      @sci\set_style_bits 8
      @sci\set_lexer Scintilla.SCLEX_CONTAINER

      buffer\add_view_ref self

  _set_appearance: =>
    @sci\set_caret_fore(0xffffff)

  on_keypress: (args) =>
    input_process @buffer, args

return TextView
