-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import BufferContext, BufferLines, BufferMarkers, Chunk, config, signal from howl
import File from howl.io
import style from howl.ui
import PropertyObject from howl.aux.moon
import destructor from howl.aux
aullar = require 'aullar'

ffi = require 'ffi'

append = table.insert
min = math.min

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
  new: (mode = {}) =>
    super!

    @_buffer = aullar.Buffer!
    @config = config.local_proxy!
    @markers = BufferMarkers @_buffer
    @completers = {}
    @mode = mode
    @properties = {}
    @data = {}
    @read_only = false
    @_len = nil
    @_eol = '\n'
    @_views = {}
    @modified = false

    @_buffer\add_listener
      on_inserted: self\_on_text_inserted
      on_deleted: self\_on_text_deleted

  @property file:
    get: => @_file
    set: (file) =>
      @_associate_with_file file

      if file.exists
        @text = file.contents
        @sync_etag = file.etag
      else
        @text = ''
        @sync_etag = nil

      @modified = false
      @can_undo = false

  @property mode:
    get: => @_mode
    set: (mode = {}) =>
      old_mode = @_mode
      @_mode = mode
      @config.chain_to mode.config
      @_buffer.lexer = mode.lexer
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
    get: => @_buffer.text
    set: (text) =>
      @_ensure_writable!
      @_buffer.text = text

  -- @property modified:
  --   get: => @sci\get_modify!
  --   set: (status) =>
  --     if not status then @sci\set_save_point!
  --     else -- there's no specific message for marking as modified
  --       @append ' '
  --       @sci\delete_range @size - 1, 1

  @property can_undo:
    get: => @_buffer.can_undo
    set: (value) => @_buffer\clear_revisions! if not value

  @property size: get: => @_buffer.size
  @property length: get: => @_buffer.length
  @property lines: get: => BufferLines self, @_buffer

  @property eol:
    get: => @_eol
    set: (eol) =>
      if eol != '\n' and eol != '\r' and eol != '\r\n'
        error 'Unknown eol mode'

      @_eol = eol

  @property showing: get: => #@_views > 0

  @property last_shown:
    get: => #@views > 0 and os.time! or @_last_shown
    set: (timestamp) => @_last_shown = timestamp

  @property multibyte: get: =>
    @_buffer.size != @_buffer.length

  @property modified_on_disk: get: =>
    return false if not @file or not @file.exists
    @file and @file.etag != @sync_etag

  chunk: (start_pos, end_pos) => Chunk self, start_pos, end_pos

  context_at: (pos) => BufferContext self, pos

  delete: (start_pos, end_pos) =>
    @_ensure_writable!
    return if start_pos > end_pos
    b_start, b_end = @byte_offset(start_pos), @byte_offset(end_pos + 1)
    @_buffer\delete b_start, b_end - b_start

  insert: (text, pos) =>
    @_ensure_writable!
    b_pos = @byte_offset pos
    @_buffer\insert b_pos, text
    pos + text.ulen

  append: (text) =>
    @_ensure_writable!
    @_buffer\insert @_buffer.size + 1, text
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
      @_buffer\replace start_pos, (end_pos - start_pos) + 1, replacement

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

  save_as: (file) =>
    @_associate_with_file file
    @save!

  as_one_undo: (f) => @_buffer\as_one_undo f

  undo: => @_buffer\undo!
  redo: => @_buffer\redo!

  char_offset: (byte_offset) =>
    if byte_offset < 1 or byte_offset > @size + 1
      error "Byte offset '#{byte_offset}' out of bounds (size = #{@size})", 2

    @_buffer\char_offset byte_offset

  byte_offset: (char_offset) =>
    if char_offset < 1 or char_offset > @length + 1
      error "Character offset '#{char_offset}' out of bounds (length = #{@length})", 2

    @_buffer\byte_offset char_offset

  sub: (start_pos, end_pos = -1) =>
    len = @length

    start_pos += len + 1 if start_pos < 0
    end_pos += len + 1 if end_pos < 0
    start_pos = 1 if start_pos < 1
    end_pos = len if end_pos > len

    byte_start_pos = @byte_offset(start_pos)
    -- we find the start of the next character
    -- to include the last byte in a multibyte character
    byte_end_pos = min @byte_offset(end_pos + 1), @_buffer.size + 1
    byte_size = byte_end_pos - byte_start_pos
    return '' if byte_size <= 0
    ffi.string @_buffer\get_ptr(byte_start_pos, byte_size), byte_size

  find: (search, init = 1) =>
    if init < 0
      init = @length + init + 1

    if init < 1 or init > @length
      return nil

    byte_start_pos, byte_end_pos = @text\find search, @byte_offset(init), true

    if byte_start_pos
      start_pos = @char_offset byte_start_pos
      end_pos = @char_offset(byte_end_pos + 1) - 1
      return start_pos, end_pos

    nil

  rfind: (search, init = @length) =>
    if init < 0
      init = @length + init + 1

    if init < 1 or init > @length
      return nil

    -- use byte offset of last byte of char at init
    byte_start_pos = @text\rfind search, @byte_offset(init + 1) - 1

    if byte_start_pos
      start_pos = @char_offset byte_start_pos
      return start_pos, start_pos + search.ulen - 1

    nil

  reload: (force = false) =>
    error "Cannot reload buffer '#{self}': no associated file", 2 unless @file
    return false if @modified and not force
    @file = @file
    signal.emit 'buffer-reloaded', buffer: self
    true

  lex: (end_pos = @size) =>
    if @_mode.lexer
      print "Buffer.lex"
      -- styler.style_text self, end_pos, @_mode.lexer

  add_view_ref: (view) =>
    append @_views, view

  remove_view_ref: (view) =>
    @_views = [v for v in *@_views when v != view and v != nil]

  @property views: get: =>
    [view for _, view in pairs @_views when view != nil]

  _ensure_writable: =>
    if @read_only
      error "Attempt to modify read-only buffer '#{@title}'", 2

  _associate_with_file: (file) =>
    buffer_titles[@_title] = nil if @_title
    @_file = file
    @title = file_title file

  _on_text_inserted: (_, _, args) =>
    @_len = nil
    @modified = true
    args.buffer = self

    signal.emit 'text-inserted', args
    signal.emit 'buffer-modified', buffer: self

  _on_text_deleted: (_, _, args) =>
    @_len = nil
    @modified = true

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
