-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:BufferContext, :BufferLines, :BufferMarkers, :Chunk, :config, :mode, :signal, :sys} = howl
{:PropertyObject} = howl.util.moon
{:File} = howl.io
{:utf8} = howl.util
aullar = require 'aullar'

ffi = require 'ffi'
ffi_string, ffi_new = ffi.string, ffi.new

append = table.insert
min = math.min

buffer_id = 0

next_id = ->
  buffer_id += 1
  return buffer_id

class Buffer extends PropertyObject
  new: (b_mode = {}) =>
    super!

    @id = next_id!
    @_buffer = aullar.Buffer!
    @markers = BufferMarkers @_buffer
    @completers = {}
    @inspectors = {}
    @mode = b_mode
    @_set_config!
    @config\clear!

    @properties = {}
    @data = {}
    @_eol = '\n'
    @viewers = 0
    @_modified = false
    @sync_revision_id = @_buffer\get_revision_id true
    @last_changed = sys.time!

    @_buffer\add_listener
      on_inserted: self\_on_text_inserted
      on_deleted: self\_on_text_deleted
      on_changed: self\_on_text_changed

  @property file:
    get: => @_file
    set: (file) =>
      @_associate_with_file file
      modified = false

      if file.exists
        contents = file.contents
        contents, changed = utf8.clean_string(contents)

        if changed > 0
          log.info "cleaned up '#{file}', now #{#contents} bytes"
          modified = true

        @_buffer.text = contents
        @sync_etag = file.etag

        -- update EOL from loaded file if possible
        first_line = @_buffer\get_line 1
        if first_line and first_line.has_eol
          eol = @_buffer\sub first_line.size + 1, first_line.end_offset
          @eol = eol

      else
        @text = ''
        @sync_etag = nil

      @can_undo = false
      @_modified = modified
      @sync_revision_id = @_buffer\get_revision_id true

  @property mode:
    get: => @_mode
    set: (new_mode = {}) =>
      old_mode = @_mode
      @_mode = new_mode
      if new_mode.lexer
        @_buffer.lexer = (text) -> new_mode.lexer text, @
      else
        @_buffer.lexer = nil

      @_set_config!
      signal.emit 'buffer-mode-set', buffer: self, mode: new_mode, :old_mode

  @property title:
    get: => @_title or (@file and @file.basename) or 'Untitled'
    set: (title) =>
      @_title = title
      signal.emit 'buffer-title-set', buffer: self

  @property text:
    get: => @_buffer.text
    set: (text) =>
      @_buffer.text = utf8.clean_string(text)

  @property modified:
    get: => @_modified
    set: (status) =>
      if status
        notify = not @_modified
        @_modified = true
        if notify
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

  @property read_only:
    get: => @_buffer.read_only
    set: (v) => @_buffer.read_only = v

  @property _config_scope:
    get: => @_file and config.scope_for_file(@_file.path) or ('buffer/' .. @id)

  chunk: (start_pos, end_pos) => Chunk self, start_pos, end_pos

  context_at: (pos) => BufferContext self, pos

  delete: (start_pos, end_pos) =>
    return if start_pos > end_pos
    b_start, b_end = @byte_offset(start_pos), @byte_offset(end_pos + 1)
    @_buffer\delete b_start, b_end - b_start

  insert: (text, pos) =>
    b_pos = @byte_offset pos
    text = utf8.clean_string(text)
    @_buffer\insert b_pos, text
    pos + text.ulen

  append: (text) =>
    text = utf8.clean_string(text)
    @_buffer\insert @_buffer.size + 1, text
    @length + 1

  replace: (pattern, replacement) =>
    matches = {}
    pos = 1
    text = @text

    while pos <= @length
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
    replacement = utf8.clean_string(replacement)

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
      if @_mode.before_save
        success, ret = pcall @_mode.before_save, @_mode, @
        log.error "Error invoking #{@_mode.name} mode before_save #{ret}" unless success
      if @config.strip_trailing_whitespace
        ws = '[\t ]'
        @replace "(#{ws}+)#{@eol}", ''
        @replace "(#{ws}+)#{@eol}?$", ''

      if @config.ensure_newline_at_eof and not @text\match "#{@eol}$"
        @append @eol

      local backup
      if @config.backup_files and @file.exists
        file_stem = "#{@file.basename}::#{ffi.C.getpid!}::#{@file.etag}"
        backup_directory = File @config.backup_directory or howl.app.settings.backupdir
        backup = backup_directory / file_stem
        status, err = pcall @file\copy, backup, {'COPY_OVERWRITE', 'COPY_ALL_METADATA'}
        if not status
          log.error "Failed to write backup file #{backup} for #{@file}: #{err}"
          backup = nil

      @file.contents = @text
      @_modified = false
      @sync_etag = @file.etag
      @sync_revision_id = @_buffer\get_revision_id true

      if backup
        status, err = pcall backup\delete
        if not status
          log.warn "Failed to delete backup file #{backup} for #{@file}: #{err}"

      signal.emit 'buffer-saved', buffer: self

  save_as: (file) =>
    @_associate_with_file file
    @save!

  rename: (file) =>
    old_file = @file
    @_associate_with_file file
    @save!
    if @file != old_file
      status, err = pcall old_file\delete
      if not status
          log.warn "Failed to delete old alias #{old_file} for #{@file}: #{err}"

  as_one_undo: (f) => @_buffer\as_one_undo f

  undo: =>
    @_buffer\undo!
    @_modified = @_buffer\get_revision_id! != @sync_revision_id
    signal.emit 'buffer-modified', buffer: self


  redo: =>
    @_buffer\redo!
    @_modified = @_buffer\get_revision_id! != @sync_revision_id

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
    ffi_string @_buffer\get_ptr(byte_start_pos, byte_size), byte_size

  get_ptr: (start_pos, end_pos) =>
    if end_pos < start_pos
      return ffi_new('const char[1]', 0), 0

    len = @length
    if not start_pos or start_pos < 1 or start_pos > len or
      not end_pos or end_pos < 1 or end_pos > len
      error "Buffer.get_ptr(): Illegal span: (#{start_pos}, #{end_pos} for buffer with length #{len}", 2

    byte_start_pos = @byte_offset(start_pos)
    byte_end_pos = min @byte_offset(end_pos + 1), @_buffer.size + 1
    count = byte_end_pos - byte_start_pos
    @_buffer\get_ptr(byte_start_pos, count), count

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
    mode_name = @_buffer.styling\get_mode_name_at b_pos
    -- Returns @mode if there's no marker or the requested mode doesn't exist.
    mode_name and mode.by_name(mode_name) or @mode

  config_at: (pos) =>
    mode_at = @mode_at pos
    return @config if mode_at == @mode
    return config.proxy @_config_scope, mode_at.config_layer

  chunk_for_span: (span, line_nr = nil) =>
    @\chunk @resolve_span span, line_nr

  resolve_span: (span, line_nr = nil) =>
    {:start_pos, :end_pos} = span
    local line, l_start_pos, l_b_start_offset

    -- resolve start pos as needed
    unless start_pos
      if span.byte_start_pos
        start_pos = @char_offset span.byte_start_pos
      elseif line_nr or span.line_nr
        line = @lines[line_nr or span.line_nr]
        start_pos = line.start_pos
        l_start_pos = line.start_pos

        if span.start_column
          start_pos = l_start_pos + span.start_column - 1
        elseif span.byte_start_column
          l_b_start_offset = line.byte_start_pos
          start_pos = @char_offset l_b_start_offset + span.byte_start_column - 1

    -- resolve end pos as needed
    unless end_pos
      if span.byte_end_pos
        end_pos = @char_offset span.byte_end_pos
      elseif span.count
        end_pos = start_pos + span.count
      elseif line_nr or span.line_nr
        line or= @lines[line_nr or span.line_nr]
        end_pos = line.end_pos

        if span.end_column
          l_start_pos or= line.start_pos
          end_pos = l_start_pos + span.end_column - 1
        elseif span.byte_end_column
          l_b_start_offset or= line.byte_start_pos
          end_pos = @char_offset l_b_start_offset + span.byte_end_column - 1

    unless start_pos and end_pos
      error "Invalid span: Failed to determine both start and end", 2

    return start_pos, end_pos

  add_view_ref: =>
    @viewers += 1

  remove_view_ref: (view) =>
    @viewers -= 1

  _associate_with_file: (file) =>
    scope = @_config_scope
    @_file = file
    config.merge scope, @_config_scope
    config.delete scope
    @_set_config!
    @title = file and file.basename or 'Untitled'

  _set_config: =>
    @config = config.proxy @_config_scope, 'default', @mode.config_layer

  _on_text_inserted: (_, _, args) =>
    @_on_buffer_modification 'text-inserted', args

  _on_text_deleted: (_, _, args) =>
    @_on_buffer_modification 'text-deleted', args

  _on_text_changed: (_, _, args) =>
    @_on_buffer_modification 'text-changed', args

  _on_buffer_modification: (what, args) =>
    @_modified = true
    @last_changed = sys.time!
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

  .define
    name: 'backup_files'
    description: 'Whether or not to make temporary backups of files while saving'
    default: false
    type_of: 'boolean'

  .define
    name: 'backup_directory'
    description: "The directory to backup files while saving"
    type_of: 'string'

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
