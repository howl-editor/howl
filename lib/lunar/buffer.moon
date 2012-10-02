import Scintilla, styler, BufferLines from lunar
import File from lunar.fs
import style from lunar.ui
import PropertyObject from lunar.aux.moon

background_sci = Scintilla!
background_buffer = nil
buffer_titles = setmetatable {}, __mode: 'v'
title_counters = {}

file_title = (file) ->
  title = file.basename
  while buffer_titles[title]
    file = file.parent
    return title if not file
    title = file.basename .. File.separator .. title

  title

title_counter = (title) ->
  title_counters[title] = 1 if not title_counters[title]
  title_counters[title] += 1
  title_counters[title]

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
      @title = file_title file
      @text = file.contents
      @dirty = false
      @can_undo = false

  @property mode:
    get: => @_mode
    set: (mode) => @_mode = mode

  @property title:
    get: => @_title or 'Untitled'
    set: (title) =>
      title ..= '<' .. title_counter(title) .. '>' if buffer_titles[title]
      @_title = title
      buffer_titles[title] = self

  @property text:
    get: => @sci\get_text!
    set: (text) =>
      @sci\clear_all!
      @sci\add_text #text, text

  @property dirty:
    get: => @sci\get_modify!
    set: (status) =>
      if not status then @sci\set_save_point!
      else -- there's no specific message for marking as dirty
        @append ' '
        @delete @size, 1

  @property can_undo:
    get: => @sci\can_undo!
    set: (value) => @sci\empty_undo_buffer! if not value

  @property size: get: => @sci\get_text_length!
  @property lines: get: => BufferLines @sci

  @property eol:
    get: =>
      switch @sci\get_eolmode!
        when Scintilla.SC_EOL_LF then '\n'
        when Scintilla.SC_EOL_CRLF then '\r\n'
        when Scintilla.SC_EOL_CR then '\r'
    set: (eol) =>
      s_mode = switch eol
        when '\n' then Scintilla.SC_EOL_LF
        when '\r\n' then Scintilla.SC_EOL_CRLF
        when '\r' then Scintilla.SC_EOL_CR
        else error 'Unknown eol mode'
      @sci\set_eolmode s_mode

  delete: (pos, length) => @sci\delete_range pos - 1, length

  insert: (text, pos) =>
    @sci\insert_text pos - 1, text
    pos + #text

  append: (text) => @sci\append_text #text, text

  save: =>
    if @file
      @file.contents = @text
      @dirty = false

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

  @meta {
    __len: => @size
    __tostring: => @title
  }

return Buffer
