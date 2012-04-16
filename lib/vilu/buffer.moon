Scintilla = require('vilu.core.scintilla')

background_sci = Scintilla!
background_buffer = nil

class Buffer
  new: =>
    @doc = background_sci\create_document!
    @views = {}

  set_text: (text) =>
    with self\connected_sci!
      \set_text text

  set_lexer: (name) =>
    self.lexer = name
    if name and @sci
      @sci\private_lexer_call(Scintilla.SCI_SETLEXERLANGUAGE, name)

  connected_sci: =>
    if @sci then return @sci

    if background_buffer != self
      background_sci\set_doc_pointer self.doc
      background_buffer = self

    return background_sci

  add_view_ref: (view) =>
    @views[view] = true
    @sci = view.sci
    self\set_lexer self.lexer

  remove_view_ref: (view) =>
    @views[view] = nil
    @sci = nil
    for view, _ in pairs @views
      @sci = view.sci
      break

return Buffer
