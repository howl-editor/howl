import Scintilla, styler from vilu
import style from vilu.ui
import PropertyObject from vilu.aux.moon

background_sci = Scintilla!
background_buffer = nil

class Buffer extends PropertyObject
  new: (mode) =>
    error('Missing argument #1 (mode)', 2) if not mode
    super!
    @_ = {}
    @doc = background_sci\create_document!
    @mode = mode
    @views = {}

  self\property mode:
    get: => @_.mode
    set: (mode) => @_.mode = mode

  self\property title:
    get: => @_.title or 'Untitled'
    set: (title) => @_.title = title

  self\property text:
    get: => @sci\get_text!
    set: (text) => @sci\set_text text

  self\property size: get: => @sci\get_text_length!

  delete: (pos, length) => @sci\delete_range pos - 1, length
  undo: => @sci\undo!

  self\property sci:
    get: =>
      if @_.sci then return @_.sci

      if background_buffer != self
        background_sci\set_doc_pointer self.doc
        background_buffer = self

      background_sci
    set: => @_.sci = nil

  add_view_ref: (view) =>
    @views[view] = true
    @_.sci = view.sci

  remove_view_ref: (view) =>
    @views[view] = nil
    @sci = nil
    for view, _ in pairs @views
      @sci = view.sci
      break

  lex: (end_pos) =>
    if @_.mode and @_.mode.lexer
      styler.style_text @sci, self, end_pos, @_.mode.lexer

return Buffer
