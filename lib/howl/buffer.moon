-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import Scintilla, styler, BufferContext, BufferLines, Chunk, config, signal from howl
import File from howl.fs
import style from howl.ui
import PropertyObject from howl.aux.moon
import destructor from howl.aux

import char_offset, byte_offset from string

background_sci = Scintilla!
background_sci\set_lexer Scintilla.SCLEX_NULL
background_buffer = setmetatable {}, __mode: 'v'
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
  new: (mode = {}, sci) =>
    super!
    @_scis = setmetatable {}, __mode: 'v'

    if sci
      @_sci = sci
      @doc = sci\get_doc_pointer!
      append @_scis, sci
    else
      @doc = background_sci\create_document!
      @destructor = destructor background_sci\release_document, @doc

    @config = config.local_proxy!
    @completers = {}
    @mode = mode
    @properties = {}
    @data = {}
    @multibyte_from = nil
    @_len = nil
    @sci_listener =
      on_text_inserted: self\_on_text_inserted
      on_text_deleted: self\_on_text_deleted

  @property file:
    get: => @_file
    set: (file) =>
      buffer_titles[@_title] = nil if @_title
      @_file = file
      @title = file_title file

      if file.exists and not @modified
        @text = file.contents
        @modified = false
        @can_undo = false
        @sync_etag = file.etag

  @property mode:
    get: => @_mode
    set: (mode = {}) =>
      had_lexer = @_mode and @_mode.lexer
      @_mode = mode
      @config.chain_to mode.config
      has_lexer = mode.lexer
      lexer = has_lexer and Scintilla.SCLEX_CONTAINER or Scintilla.SCLEX_NULL
      sci\set_lexer lexer for sci in *@scis

      if has_lexer
        @sci\colourise 0, @sci\get_end_styled!
      elseif had_lexer
        styler.clear_styling @sci, self

  @property title:
    get: => @_title or 'Untitled'
    set: (title) =>
      buffer_titles[@_title] = nil if @_title
      title ..= '<' .. title_counter(title) .. '>' if buffer_titles[title]
      @_title = title
      buffer_titles[title] = self
      signal.emit 'buffer-title-set', buffer: self

  @property text:
    get: => @sci\get_text!
    set: (text) =>
      @sci\clear_all!
      @sci\set_code_page Scintilla.SC_CP_UTF8
      @sci\add_text #text, text
      @multibyte_from = text.multibyte and 0 or nil

  @property modified:
    get: => @sci\get_modify!
    set: (status) =>
      if not status then @sci\set_save_point!
      else -- there's no specific message for marking as modified
        @append ' '
        @sci\delete_range @size - 1, 1

  @property can_undo:
    get: => @sci\can_undo!
    set: (value) => @sci\empty_undo_buffer! if not value

  @property size: get: => @sci\get_text_length!

  @property length: get: =>
    @_len or= @sci\count_characters 0, @size
    @multibyte_from = nil if @_len == @size
    @_len

  @property lines: get: => BufferLines self, @sci

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

  @property showing: get: => #@scis > 0

  @property last_shown:
    get: => #@scis > 0 and os.time! or @_last_shown
    set: (timestamp) => @_last_shown = timestamp

  @property destroyed: get: => @doc == nil

  @property multibyte: get: => @multibyte_from != nil

  @property modified_on_disk: get: =>
    return false unless @file
    @file and @file.etag != @sync_etag

  @property read_only:
    get: => @sci\get_read_only!
    set: (status) => @sci\set_read_only status

  destroy: =>
    return if @destroyed
    error 'Cannot destroy a currently showing buffer', 2 if @showing

    if @destructor
      @destructor.defuse!
      @sci\release_document @doc
      @destructor = nil

    @doc = nil

  chunk: (start_pos, end_pos) => Chunk self, start_pos, end_pos

  context_at: (pos) => BufferContext self, pos

  delete: (start_pos, end_pos) =>
    return if start_pos > end_pos
    b_start, b_end = @byte_offset start_pos, end_pos + 1
    @sci\delete_range b_start - 1, b_end - b_start

  insert: (text, pos) =>
    b_pos = @byte_offset pos
    @sci\insert_text b_pos - 1, text
    pos + text.ulen

  append: (text) =>
    @sci\append_text #text, text
    @length + 1

  replace: (pattern, replacement) =>
    matches = {}
    pos = 1
    text = @text

    while pos < @length
      start_pos, end_pos, match = text\ufind pattern, pos
      break unless start_pos

      -- only replace the match within pattern if present
      end_pos = match and (start_pos + #match - 1) or end_pos

      append matches, start_pos
      append matches, end_pos
      pos = end_pos + 1

    return if #matches == 0
    b_offsets = @byte_offset matches

    for i = #b_offsets, 1, -2
      start_pos = b_offsets[i - 1]
      end_pos = b_offsets[i]

      with @sci
        \set_target_start start_pos - 1
        \set_target_end end_pos
        \replace_target -1, replacement

    #matches / 2

  save: =>
    if @file
      if @config.strip_trailing_whitespace
        ws = '[\t ]'
        @replace "(#{ws}+)#{@eol}", ''
        @replace "(#{ws}+)$", ''

      @file.contents = @text
      @modified = false
      @sync_etag = @file.etag
      signal.emit 'buffer-saved', buffer: self

  as_one_undo: (f) =>
    @sci\begin_undo_action!
    status, ret = pcall f
    @sci\end_undo_action!
    error ret if not status

  undo: => @sci\undo!
  redo: => @sci\redo!
  char_offset: (...) => @_offset char_offset, ...
  byte_offset: (...) => @_offset byte_offset, ...

  reload: =>
    error "Cannot reload buffer '#{self}': no associated file", 2 unless @file
    @file = @file
    signal.emit 'buffer-reloaded', buffer: self

  @property sci:
    get: =>
      error 'Attempt to invoke operation on destroyed buffer', 2 if @destroyed
      if @_sci then return @_sci

      if background_buffer[1] != self
        background_sci\set_doc_pointer self.doc
        background_buffer[1] = self
        background_sci.listener = @sci_listener

      background_sci

  add_sci_ref: (sci) =>
    append @_scis, sci
    @_sci = sci
    if background_buffer[1] == self
      background_sci.listener = nil

    sci\set_style_bits 8
    sci\set_lexer @_mode.lexer and Scintilla.SCLEX_CONTAINER or Scintilla.SCLEX_NULL

  remove_sci_ref: (sci) =>
    @_scis = [s for s in *@_scis when s != sci and s != nil]
    @_sci = @_scis[1] if sci == @_sci
    @_last_shown = os.time! if #@_scis == 0

  lex: (end_pos) =>
    if @_mode.lexer
      styler.style_text self, end_pos, @_mode.lexer

  @property scis: get: =>
    [sci for _, sci in pairs @_scis when sci != nil]

  _on_text_inserted: (args) =>
    @_len = nil

    if args.text
      if args.text.multibyte
        @multibyte_from = @multibyte_from and math.min(@multibyte_from, args.at_pos) or args.at_pos
    elseif @length != @size
      @multibyte_from = math.min(@multibyte_from or 0, args.at_pos)

    signal.emit 'buffer-modified', buffer: self

  _on_text_deleted: (args) =>
    if @multibyte and args.at_pos < @multibyte_from
      @multibyte_from = args.at_pos

    @_len = nil
    signal.emit 'buffer-modified', buffer: self

  _offset: (f, ...) =>
    args = {...}
    is_table = type(args[1]) == 'table'
    arg_offsets = is_table and args[1] or args
    local offsets

    if @multibyte and arg_offsets[#arg_offsets] >= @multibyte_from
      offsets = f @text, arg_offsets
      for i = #offsets, 1, -1
        res = offsets[i]
        arg = arg_offsets[i]
        if res == arg
          @multibyte_from = res
          break
    else
      offsets = {}
      size = @size
      for offset in *arg_offsets
        if offset < 1 or offset > size + 1
          error "Offset '#{offset}' out of bounds (size = #{size})", 2
        append offsets, offset

    return offsets if is_table
    return table.unpack offsets

  @meta {
    __len: => @length
    __tostring: => @title
  }

-- Config variables

with config
  .define
    name: 'strip_trailing_whitespace'
    description: 'Whether trailing whitespace will be removed upon save'
    default: true
    type_of: 'boolean'

-- Signals

signal.register 'buffer-saved',
  description: 'Signaled right after a buffer was saved',
  parameters:
    buffer: 'The buffer that was saved'

signal.register 'buffer-modified',
  description: 'Signaled right after a buffer was modified',
  parameters:
    buffer: 'The buffer that was modified'

signal.register 'buffer-reloaded',
  description: 'Signaled right after a buffer was reloaded',
  parameters:
    buffer: 'The buffer that was reloaded'

signal.register 'buffer-title-set',
  description: 'Signaled right after a buffer had its title set',
  parameters:
    buffer: 'The buffer receiving the new title'

return Buffer
