import Gtk from lgi
Scintilla = require('vilu.core.scintilla')

class TextView

  new: (buffer) =>
    error('Missing argument #1 (buffer)', 2) if not buffer
    @sci = Scintilla!
    self\set_buffer buffer
    self\_set_appearance!

    getmetatable(self).__towidget = => @sci\get_widget!

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

return TextView
