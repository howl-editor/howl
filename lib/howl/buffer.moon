-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Scintilla, styler, BufferContext, BufferLines, Chunk, config, signal from howl
import File from howl.io
import style from howl.ui
import PropertyObject from howl.aux.moon
import destructor from howl.aux

ffi = require 'ffi'

append = table.insert

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

      if file.exists
        @text = file.contents
        @modified = false
        @can_undo = false
        @sync_etag = file.etag
      else
        @sync_etag = nil


  @property mode:
    get: => @_mode
    set: (mode = {}) =>
      old_mode = @_mode
      had_lexer = old_mode and old_mode.lexer
      @_mode = mode
      @config.chain_to mode.config
      has_lexer = mode.lexer
      lexer = has_lexer and Scintilla.SCLEX_CONTAINER or Scintilla.SCLEX_NULL
      sci\set_lexer lexer for sci in *@scis

      if has_lexer
        @sci\colourise 0, @sci\get_end_styled!
      elseif had_lexer
        styler.clear_styling @sci, self

      signal.emit 'buffer-mode-set', buffer: self, :mode, :old_mode

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
    @_len or= @sci\character_count!
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

  @property multibyte: get: => @sci\is_multibyte!

  @property modified_on_disk: get: =>
    return false if not @file or not @file.exists
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
    b_start, b_end = @byte_offset(start_pos), @byte_offset(end_pos + 1)
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
    b_offsets = text\byte_offset matches

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
        @replace "(#{ws}+)#{@eol}?$", ''

      if @config.ensure_newline_at_eof and not @text\match "#{@eol}$"
        @append @eol

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

  char_offset: (byte_offset) =>
    if byte_offset < 1 or byte_offset > @size + 1
      error "Byte offset '#{byte_offset}' out of bounds (size = #{@size})", 2

    1 + @sci\char_offset byte_offset - 1

  byte_offset: (char_offset) =>
    if char_offset < 1 or char_offset > @length + 1
      error "Character offset '#{char_offset}' out of bounds (length = #{@length})", 2

    1 + @sci\byte_offset char_offset - 1

  sub: (start_pos, end_pos = -1) =>
    if start_pos < 0
      start_pos = @length + start_pos + 1
    if end_pos < 0
      end_pos = @length + end_pos + 1
    byte_start_pos = @\byte_offset(start_pos)
    -- we find the start of the next character
    -- to include the last byte in a multibyte character
    byte_end_pos = @\byte_offset(end_pos + 1)
    byte_size = byte_end_pos - byte_start_pos
    if byte_size <= 0
      return ''
    ffi.string @sci\get_range_pointer(byte_start_pos - 1, byte_size), byte_size

  reload: (force = false) =>
    error "Cannot reload buffer '#{self}': no associated file", 2 unless @file
    return false if @modified and not force
    @file = @file
    signal.emit 'buffer-reloaded', buffer: self
    true

  @property sci:
    get: =>
      error 'Attempt to invoke operation on destroyed buffer', 3 if @destroyed
      if @_sci then return @_sci

      if background_buffer[1] != self
        background_sci\set_doc_pointer self.doc
        background_sci\set_code_page Scintilla.SC_CP_UTF8
        background_buffer[1] = self
        background_sci.listener = @sci_listener

      background_sci

  lex: (end_pos = @size) =>
    if @_mode.lexer
      styler.style_text self, end_pos, @_mode.lexer

  add_sci_ref: (sci) =>
    append @_scis, sci
    @_sci = sci
    if background_buffer[1] == self
      background_sci.listener = nil

    sci\set_code_page Scintilla.SC_CP_UTF8
    sci\set_style_bits 8
    sci\set_lexer @_mode.lexer and Scintilla.SCLEX_CONTAINER or Scintilla.SCLEX_NULL

  remove_sci_ref: (sci) =>
    @_scis = [s for s in *@_scis when s != sci and s != nil]
    @_sci = @_scis[1] if sci == @_sci
    @_last_shown = os.time! if #@_scis == 0

  @property scis: get: =>
    [sci for _, sci in pairs @_scis when sci != nil]

  _on_text_inserted: (args) =>
    @_len = nil
    args.buffer = self
    signal.emit 'text-inserted', args
    signal.emit 'buffer-modified', buffer: self

  _on_text_deleted: (args) =>
    @_len = nil

    args.buffer = self
    signal.emit 'text-deleted', args
    signal.emit 'buffer-modified', buffer: self

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

  .define
    name: 'ensure_newline_at_eof'
    description: 'Whether to ensure a trailing newline is present at eof upon save'
    default: true
    type_of: 'boolean'

-- Signals

with signal
  .register 'buffer-saved',
    description: 'Signaled right after a buffer was saved',
    parameters:
      buffer: 'The buffer that was saved'

  .register 'text-inserted',
    description: [[
Signaled right after text has been inserted into an editor. No additional
modifications  may be done within the signal handler.
  ]]
    parameters:
      buffer: 'The buffer for which the text was inserted'
      editor: '(Optional) The editor containing the buffer'
      at_pos: 'The byte start position of the inserted text'
      length: 'The number of characters in the inserted text'
      text: 'The text that was inserted'
      lines_added: 'The number of lines that were added'
      as_undo: 'The text was inserted as part of an undo operation'
      as_redo: 'The text was inserted as part of a redo operation'

  .register 'text-deleted',
    description: [[
Signaled right after text was deleted from the editor. No additional
modifications may be done within the signal handler.
  ]]
    parameters:
      buffer: 'The buffer for which the text was deleted'
      editor: '(Optional) The editor containing the buffer'
      at_pos: 'The byte start position of the deleted text'
      length: 'The number of characters that was deleted'
      text: 'The text that was deleted'
      lines_deleted: 'The number of lines that were deleted'
      as_undo: 'The text was deleted as part of an undo operation'
      as_redo: 'The text was deleted as part of a redo operation'

  .register 'buffer-modified',
    description: 'Signaled right after a buffer was modified',
    parameters:
      buffer: 'The buffer that was modified'
      as_undo: 'The buffer was modified as the result of an undo operation'
      as_redo: 'The buffer was modified as the result of a redo operation'

  .register 'buffer-reloaded',
    description: 'Signaled right after a buffer was reloaded',
    parameters:
      buffer: 'The buffer that was reloaded'

  .register 'buffer-mode-set',
    description: 'Signaled right after a buffer had its mode set',
    parameters:
      buffer: 'The target buffer'
      mode: 'The new mode that was set'
      old_mode: 'The old mode if any'

  .register 'buffer-title-set',
    description: 'Signaled right after a buffer had its title set',
    parameters:
      buffer: 'The buffer receiving the new title'

return Buffer
