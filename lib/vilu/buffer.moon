import Scintilla, styler, BufferLines from vilu
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
    @scis = {}

  @property mode:
    get: => @_.mode
    set: (mode) => @_.mode = mode

  @property title:
    get: => @_.title or 'Untitled'
    set: (title) => @_.title = title

  @property text:
    get: => @sci\get_text!
    set: (text) => @sci\set_text text

  @property dirty:
    get: => @sci\get_modify!
    set: (status) =>
      if not status then @sci\set_save_point!
      else -- there's no specific message for marking as dirty
        self\append ' '
        self\delete @size, 1

  @property size: get: => @sci\get_text_length!
  @property lines: get: => BufferLines @sci

  delete: (pos, length) => @sci\delete_range pos - 1, length
  insert: (text, pos) => @sci\insert_text pos - 1, text
  append: (text) => @sci\append_text #text, text

  as_one_undo: (f) =>
    @sci\begin_undo_action!
    status, ret = pcall f
    @sci\end_undo_action!
    error ret if not status

  undo: => @sci\undo!
  clear_undo_history: => @sci\empty_undo_buffer!

  @property sci:
    get: =>
      if @_.sci then return @_.sci

      if background_buffer != self
        background_sci\set_doc_pointer self.doc
        background_buffer = self

      background_sci

    set: => @_.sci = nil

  add_sci_ref: (sci) =>
    @scis[sci] = true
    @_.sci = sci

  remove_sci_ref: (sci) =>
    @scis[sci] = nil
    @sci = nil
    for sci, _ in pairs @scis
      @sci = sci
      break

  lex: (end_pos) =>
    if @_.mode and @_.mode.lexer
      styler.style_text @sci, self, end_pos, @_.mode.lexer

return Buffer
