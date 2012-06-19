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
    @editors = {}

  self\property mode:
    get: => @_.mode
    set: (mode) => @_.mode = mode

  self\property title:
    get: => @_.title or 'Untitled'
    set: (title) => @_.title = title

  self\property text:
    get: => @sci\get_text!
    set: (text) => @sci\set_text text

  self\property dirty:
    get: => @sci\get_modify!
    set: (status) =>
      if not status then @sci\set_save_point!
      else -- there's no specific message for marking as dirty
        self\append ' '
        self\delete @size, 1

  self\property size: get: => @sci\get_text_length!
  self\property lines: get: => BufferLines @sci

  delete: (pos, length) => @sci\delete_range pos - 1, length
  insert: (text, pos) => @sci\insert_text pos - 1, text
  append: (text) => @sci\append_text #text, text
  undo: => @sci\undo!
  clear_undo_history: => @sci\empty_undo_buffer!

  self\property sci:
    get: =>
      if @_.sci then return @_.sci

      if background_buffer != self
        background_sci\set_doc_pointer self.doc
        background_buffer = self

      background_sci
    set: => @_.sci = nil

  add_editor_ref: (editor) =>
    @editors[editor] = true
    @_.sci = editor.sci

  remove_editor_ref: (editor) =>
    @editors[editor] = nil
    @sci = nil
    for editor, _ in pairs @editors
      @sci = editor.sci
      break

  lex: (end_pos) =>
    if @_.mode and @_.mode.lexer
      styler.style_text @sci, self, end_pos, @_.mode.lexer

return Buffer
