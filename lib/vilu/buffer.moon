import Scintilla, styler, BufferLines from vilu
import style from vilu.ui
import PropertyObject from vilu.aux.moon

background_sci = Scintilla!
background_buffer = nil

class Buffer extends PropertyObject
  new: (mode, sci) =>
    error('Missing argument #1 (mode)', 2) if not mode
    super!

    if sci
      @_sci = sci
      @doc = sci\get_doc_pointer!
      @scis = { sci }
    else
      @doc = background_sci\create_document!
      @scis = {}

    @mode = mode

  @property file:
    get: => @_file
    set: (file) =>
      @_file = file
      @title = file.basename
      @text = file.contents
      @dirty = false
      @can_undo = false

  @property mode:
    get: => @_mode
    set: (mode) => @_mode = mode

  @property title:
    get: => @_title or 'Untitled'
    set: (title) => @_title = title

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

  @property can_undo:
    get: => @sci\can_undo!
    set: (value) => @sci\empty_undo_buffer! if not value

  @property size: get: => @sci\get_text_length!
  @property lines: get: => BufferLines @sci

  delete: (pos, length) => @sci\delete_range pos - 1, length

  insert: (text, pos) =>
    @sci\insert_text pos - 1, text
    pos + #text

  append: (text) => @sci\append_text #text, text

  as_one_undo: (f) =>
    @sci\begin_undo_action!
    status, ret = pcall f
    @sci\end_undo_action!
    error ret if not status

  undo: => @sci\undo!

  @property sci:
    get: =>
      if @_sci then return @_sci

      if background_buffer != self
        background_sci\set_doc_pointer self.doc
        background_buffer = self

      background_sci

  add_sci_ref: (sci) =>
    append @scis, sci
    @_sci = sci

  remove_sci_ref: (sci) =>
    @scis = [s for s in *@scis when s != sci]
    @_sci = @scis[1] if sci == @_sci

  lex: (end_pos) =>
    if @_mode and @_mode.lexer
      styler.style_text @sci, self, end_pos, @_mode.lexer

  __len: => @size

return Buffer
