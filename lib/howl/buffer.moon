-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import BufferContext, BufferLines, BufferMarkers, Chunk, config, signal, sys from howl
import File from howl.io
import style from howl.ui
import PropertyObject from howl.aux.moon
import destructor from howl.aux
import mode from howl
aullar = require 'aullar'
{:copy} = moon

ffi = require 'ffi'

append = table.insert
min = math.min

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
    @_eol = '\n'
    @viewers = 0
    @_modified = false

    @_buffer\add_listener
      on_inserted: self\_on_text_inserted
      on_deleted: self\_on_text_deleted
      on_changed: self\_on_text_changed

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

      @_modified = false
      @can_undo = false

  @property mode:
    get: => @_mode
    set: (mode = {}) =>
      old_mode = @_mode
      @_mode = mode
      @config.chain_to mode.config
      if mode.lexer
        @_buffer.lexer = (text) -> mode.lexer text, @
      else
        @_buffer.lexer = nil

      signal.emit 'buffer-mode-set', buffer: self, :mode, :old_mode

  @property title:
    get: => @_title or (@file and @file.basename) or 'Untitled'
    set: (title) =>
      @_title = title
      signal.emit 'buffer-title-set', buffer: self

  @property text:
    get: => @_buffer.text
    set: (text) =>
      @_ensure_writable!
      @_buffer.text = text

  @property modified:
    get: => @_modified
    set: (status) =>
      if status
        notify = not @_modified
        @_modified = true
        if not @_modified
          signal.emit 'buffer-modified', buffer: self
      else
        @_modified = false

  @property can_undo:
    get: => @_buffer.can_undo
    set: (value) => @_buffer\clear_revisions! if not value

  @property collect_revisions:
    get: => @_buffer.collect_revisions
    set: (v) => @_buffer.collect_revisions = v

  @property size: get: => @_buffer.size
  @property length: get: => @_buffer.length
  @property lines: get: => BufferLines self, @_buffer

  @property eol:
    get: => @_eol
    set: (eol) =>
      if eol != '\n' and eol != '\r' and eol != '\r\n'
        error 'Unknown eol mode'

      @_eol = eol

  @property showing: get: => @viewers > 0

  @property last_shown:
    get: => @viewers > 0 and sys.time! or @_last_shown
    set: (timestamp) => @_last_shown = timestamp

  @property multibyte: get: =>
    @_buffer.multibyte

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

    if @multibyte
      matches = [@_buffer\byte_offset(p) for p in *matches]

    offset = matches[1]
    count = matches[#matches] - offset + 1

    @_buffer\change offset, count, ->
      for i = #matches, 1, -2
        start_pos = matches[i - 1]
        end_pos = matches[i]
        @_buffer\replace start_pos, (end_pos - start_pos) + 1, replacement

    #matches / 2

  change: (start_pos, end_pos, changer) =>
    b_start, b_end = @byte_offset(start_pos), @byte_offset(end_pos + 1)
    @_buffer\change b_start, b_end - b_start, ->
      changer @

  save: =>
    if @file
      if @config.strip_trailing_whitespace
        ws = '[\t ]'
        @replace "(#{ws}+)#{@eol}", ''
        @replace "(#{ws}+)#{@eol}?$", ''

      if @config.ensure_newline_at_eof and not @text\match "#{@eol}$"
        @append @eol

      @file.contents = @text
      @_modified = false
      @sync_etag = @file.etag
      signal.emit 'buffer-saved', buffer: self

  save_as: (file) =>
    @_associate_with_file file
    @save!

  as_one_undo: (f) => @_buffer\as_one_undo f

  undo: => @_buffer\undo!
  redo: => @_buffer\redo!

  char_offset: (byte_offset) =>
    @_buffer\char_offset byte_offset

  byte_offset: (char_offset) =>
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
    return false if @_modified and not force
    @file = @file
    signal.emit 'buffer-reloaded', buffer: self
    true

  lex: (end_pos = @size) =>
    if @_mode.lexer
      b_end_pos = @byte_offset end_pos
      @_buffer\ensure_styled_to pos: b_end_pos

  mode_at: (pos) =>
    b_pos = @byte_offset pos
    marker = @_buffer.styling\get_nearest_style_marker b_pos
    if marker then mode.by_name marker.name else @mode

  config_at: (pos) =>
    new_config = config.local_proxy!
    mode_at = @mode_at pos
    return @config if mode_at == @mode
    new_config.chain_to @mode_at(pos).config
    new_config

  add_view_ref: =>
    @viewers += 1

  remove_view_ref: (view) =>
    @viewers -= 1

  _ensure_writable: =>
    if @read_only
      error "Attempt to modify read-only buffer '#{@title}'", 2

  _associate_with_file: (file) =>
    @_file = file
    @title = file and file.basename or 'Untitled'

  _on_text_inserted: (_, _, args) =>
    @_on_buffer_modification 'text-inserted', args

  _on_text_deleted: (_, _, args) =>
    @_on_buffer_modification 'text-deleted', args

  _on_text_changed: (_, _, args) =>
    @_on_buffer_modification 'text-changed', args

  _on_buffer_modification: (what, args) =>
    @_modified = true
    args = {
      buffer: self,
      at_pos: @char_offset(args.offset),
      part_of_revision: args.part_of_revision,
      text: args.text
      prev_text: args.prev_text
    }

    signal.emit what, args
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
Signaled right after text has been inserted into a buffer. No additional
modifications  may be done within the signal handler.
  ]]
    parameters:
      buffer: 'The buffer for which the text was inserted'
      at_pos: 'The start position of the inserted text'
      text: 'The text that was inserted'
      part_of_revision: 'The text was inserted as part of an undo or redo operation'

  .register 'text-deleted',
    description: [[
Signaled right after text was deleted from a buffer. No additional
modifications may be done within the signal handler.
  ]]
    parameters:
      buffer: 'The buffer for which the text was deleted'
      at_pos: 'The start position of the deleted text'
      text: 'The text that was deleted'
      part_of_revision: 'The text was deleted as part of an undo or redo operation'

  .register 'text-changed',
    description: [[
Signaled right after text was changed in a buffer. No additional
modifications may be done within the signal handler.
  ]]
    parameters:
      buffer: 'The buffer for which the text was deleted'
      at_pos: 'The start position of the deleted text'
      text: 'The new text that was inserted'
      prev_text: 'The text that was removed'
      part_of_revision: 'The text was changed as part of an undo or redo operation'

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
