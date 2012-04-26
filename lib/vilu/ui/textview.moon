import Gtk from lgi
import Scintilla from vilu

input_process = vilu.input.process

class TextView

  new: (buffer) =>
    error('Missing argument #1 (buffer)', 2) if not buffer

    @sci = Scintilla!
    @sci.on_keypress = self\on_keypress
    self\set_buffer buffer
    self\_set_appearance!

    getmetatable(self).__to_gobject = => @sci\get_gobject!

  set_buffer: (buffer) =>
    if @buffer
      @buffer\remove_view_ref self

    @buffer = buffer
    @sci\set_doc_pointer(buffer.doc)
    self._init_scintillua @sci

    buffer\add_view_ref self

  grab_focus: =>
    @sci\grab_focus!

  _set_appearance: =>
    @sci\set_caret_fore(0xffffff)

  _init_scintillua: (sci) ->
    lexer_home = vilu.app.root_dir / 'lexers'
    with sci
      \set_lexer_language 'lpeg'
      \set_property('lexer.lpeg.home', tostring(lexer_home))
      \set_property('lexer.lpeg.color.theme', 'dark')
      dir_f = \get_direct_function!
      dir_p = \get_direct_pointer!
      \private_lexer_call(Scintilla.SCI_GETDIRECTFUNCTION, dir_f)
      \private_lexer_call(Scintilla.SCI_SETDOCPOINTER, dir_p)

  on_keypress: (args) =>
    input_process self.buffer, args

return TextView
