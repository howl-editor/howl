import Scintilla, styler from vilu
import style from vilu.ui
import PropertyObject from vilu.aux.moon

background_sci = Scintilla!
background_buffer = nil

class Buffer extends PropertyObject
  new: (mode) =>
    error('Missing argument #1 (mode)', 2) if not mode
    super!
    @doc = background_sci\create_document!
    @mode = mode
    @views = {}

  self\property mode:
    get: => @_mode
    set: (mode) => @_mode = mode

  self\property text:
    get: => self\connected_sci!\get_text!
    set: (text) =>
      self\connected_sci!\set_text text

  self\property lexer:
      get: => @_lexer
      set: (name) =>
        @_lexer = name
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
    @lexer = @_lexer

  remove_view_ref: (view) =>
    @views[view] = nil
    @sci = nil
    for view, _ in pairs @views
      @sci = view.sci
      break

  lex: (end_pos) =>
    if @_mode and @_mode.lexer
      styler.style_text self\connected_sci!, self, end_pos, @_mode.lexer

return Buffer
