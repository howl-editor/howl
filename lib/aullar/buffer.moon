-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C, ffi_string, ffi_copy = ffi.C, ffi.string, ffi.copy
{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Styling = require 'aullar.styling'
Offsets = require 'aullar.offsets'
GapBuffer = require 'aullar.gap_buffer'
Revisions = require 'aullar.revisions'
require 'ljglibs.cdefs.glib'

char_arr = ffi.typeof 'char [?]'

scan_line = (base, offset, end_offset) ->
  start_offset = offset
  was_eol = false

  byte = base[offset]
  while byte != 10 and byte != 13 and offset < end_offset
    offset += 1
    byte = base[offset]

  l_size = offset - start_offset

  if offset < end_offset -- break due to EOL
    eol_byte = byte
    was_eol = true
    offset += 1
    if eol_byte == 13 and offset < end_offset
      byte = base[offset]
      if byte == 10
        offset += 1

  offset, l_size, was_eol

LineMt = {
  __index: (line, k) ->
    if k == 'text'
      ffi_string line.ptr, line.size
}

Buffer = {
  new: (text = '') =>
    @listeners = {}
    @_style_listener = on_changed: self\_on_style_changed
    @revisions = Revisions!
    @text = text
    @revisions\clear!

  properties: {
    size: => @text_buffer.size
    length: => @_length
    can_undo: => #@revisions > 0

    nr_lines: =>
      @_scan_lines_to {}
      @_last_scanned_line

    lexer: {
      get: => @_lexer
      set: (lexer) =>
        @_lexer = lexer
        @styling\invalidate_from 1
    }

    text: {
      get: => @tostring!
      set: (text) =>
        old_text = @text_buffer and @tostring!
        size = #text
        @text_buffer = GapBuffer 'char', size, initial: text
        -- +1 on styling size to account for dangling virtual line
        @styling = Styling size + 1, @_style_listener
        @_last_scanned_line = 0
        @_lines = {}
        @offsets = Offsets!
        @_length = @offsets\char_offset(@text_buffer, @text_buffer.size)

        @as_one_undo ->
          if old_text
            @_on_modification 'deleted', 1, old_text, #old_text, 0

          @_on_modification 'inserted', 1, text, size, 0

    }
  }

  add_listener: (listener) =>
    @listeners[#@listeners + 1] = listener

  remove_listener: (listener) =>
    @listeners = [l for l in *@listeners when l != listener]

  insert: (offset, text, size = #text) =>
    return if size == 0

    invalidate_offset = min(offset, @text_buffer.gap_start + 1)
    if size > @text_buffer.gap_size
      invalidate_offset = 1

    len = C.g_utf8_strlen text, size
    @text_buffer\insert offset - 1, text
    @_length += len
    @_invalidate_lines_from_offset invalidate_offset
    @offsets\adjust_for_insert invalidate_offset - 1, size, len
    @styling\insert offset, size, no_notify: true

    @_on_modification 'inserted', offset, text, size, invalidate_offset

  delete: (offset, count) =>
    return if count == 0

    invalidate_offset = min(offset, @text_buffer.gap_start + 1)
    text = @sub offset, offset + count - 1
    len = C.g_utf8_strlen text, count
    @text_buffer\delete offset - 1, count
    @_length -= len
    @_invalidate_lines_from_offset invalidate_offset
    @offsets\adjust_for_delete invalidate_offset - 1, count, len
    @styling\delete offset, count, no_notify: true

    @_on_modification 'deleted', offset, text, count, invalidate_offset

  replace: (offset, count, replacement, replacement_size = #replacement) =>
    @delete offset, count
    @insert offset, replacement, replacement_size

  lines: (start_line = 1, end_line) =>
    i = start_line - 1
    lines = @_lines
    ->
      i += 1
      @_scan_lines_to line: i
      return nil if i > @_last_scanned_line
      lines[i]

  get_line: (line) =>
    @_scan_lines_to(:line) if @_last_scanned_line < line
    @_lines[line]

  get_line_at_offset: (offset) =>
    @_scan_lines_to :offset
    start_at, end_at, step = 1, @_last_scanned_line, 1
    last_line = @_lines[@_last_scanned_line]
    if last_line and abs(last_line.start_offset - offset) < offset
      start_at, end_at, step = last_line.nr, 1, -1

    for i = start_at, end_at, step
      line = @_lines[i]

      if offset >= line.start_offset
        if offset <= line.end_offset or (not line.has_eol and offset == line.end_offset + 1)
          return line

    nil

  get_ptr: (offset, size) =>
    @text_buffer\get_ptr offset - 1, size

  sub: (start_index, end_index) =>
    return '' if start_index > @size
    end_index or= @size
    end_index = @size if end_index > @size
    size = (end_index - start_index) + 1
    return '' if size == 0
    ffi_string(@get_ptr(start_index, size), size)

  style: (offset, styling) =>
    @styling\apply offset, styling

  refresh_styling_at: (line_nr, to_line, opts = {}) =>
    lexer = @lexer
    at_line = @get_line line_nr
    return unless at_line and lexer

    last_styled_line = 1
    start_line = at_line
    if (@styling.last_pos_styled + 1) < start_line.start_offset
      start_line = @get_line_at_offset(@styling.last_pos_styled + 1)

    -- find the starting line to lex from
    while start_line.nr > 1
      prev_eol_style = @styling\at start_line.start_offset - 1
      break if not prev_eol_style or prev_eol_style == 'whitespace'
      start_line = @get_line(start_line.nr - 1)

    start_offset = start_line.start_offset
    at_line_eol_style = @styling\at(at_line.end_offset) or 'whitespace'

    styled = nil

    if not opts.force_full
      -- try lexing only up to this line
      text = @sub start_offset, at_line.end_offset
      @styling\clear start_offset, at_line.end_offset, no_notify: true
      @styling\apply start_offset, lexer(text), no_notify: true
      new_at_line_eol_style = @styling\at(at_line.end_offset) or 'whitespace'
      if new_at_line_eol_style == at_line_eol_style
        styled = start_line: at_line.nr, end_line: at_line.nr, invalidated: false

    unless styled
      @styling\invalidate_from at_line.start_offset, no_notify: true
      end_line = @get_line(to_line) or @get_line(@nr_lines)
      text = @sub start_offset, end_line.end_offset
      @styling\apply start_offset, lexer(text), no_notify: true
      @styling.last_pos_styled = end_line.end_offset
      styled = start_line: at_line.nr, end_line: end_line.nr, invalidated: true

    @notify('styled', styled) unless opts.no_notify
    styled

  ensure_styled_to: (line_nr) =>
    return unless @lexer
    to_line = @get_line min(line_nr + 20, @nr_lines)
    return unless to_line and @styling.last_pos_styled < to_line.end_offset

    from_line = @get_line_at_offset max(1, @styling.last_pos_styled)
    @refresh_styling_at from_line.nr, to_line.nr, force_full: true

  tostring: =>
    if @text_buffer.gap_size != 0
      @text_buffer\compact!
      @offsets\invalidate_from 0
      @_invalidate_lines_from_offset 0

    return ffi_string @text_buffer.array, @text_buffer.size

  char_offset: (byte_offset) =>
    @offsets\char_offset(@text_buffer, byte_offset - 1) + 1

  byte_offset: (char_offset) =>
    @offsets\byte_offset(@text_buffer, char_offset - 1) + 1

  undo: =>
    revision = @revisions\pop @
    @notify('undo', revision) if revision

  redo: =>
    revision = @revisions\forward @
    @notify('redo', revision) if revision

  as_one_undo: (f) =>
    @revisions\start_group!
    status, ret = pcall f
    @revisions\end_group!
    error ret unless status

  clear_revisions: => @revisions\clear!

  notify: (event, parameters) =>
    for listener in *@listeners
      callback = listener["on_#{event}"]
      if callback
        status, ret = pcall callback, listener, @, parameters
        print "Error emitting '#{event}': #{ret}" unless status

  _scan_lines_to: (to) =>
    tb = @text_buffer
    bytes = tb.array
    offset = 0
    base_offset = 0
    base = bytes
    nr = 0
    lines = @_lines
    size = tb.size
    bytes_size = size + tb.gap_size
    last_was_eol = false
    z_gap_start = tb.gap_start
    z_gap_end = tb.gap_end

    if @_last_scanned_line > 0
      with lines[@_last_scanned_line]
        offset = .end_offset
        nr = .nr
        last_was_eol = .has_eol

    stop_scan_at = bytes_size

    if offset >= z_gap_start
      base_offset += tb.gap_size
      offset += tb.gap_size
    else
      stop_scan_at = z_gap_start

    while (not to.line or nr < to.line) and (not to.offset or (offset - base_offset) < to.offset)
      text_ptr = base + offset
      start_p = offset - base_offset
      next_p, l_size, was_eol = scan_line base, offset, stop_scan_at

      if not was_eol and stop_scan_at != bytes_size -- at gap
        base_offset += tb.gap_size
        stop_scan_at = bytes_size
        next_p, cont_l_size, was_eol = scan_line bytes, z_gap_end, stop_scan_at
        if cont_l_size > 0 -- else gap is at end, nothing left
          gap_line = char_arr(l_size + cont_l_size)
          ffi_copy gap_line, text_ptr, l_size
          ffi_copy gap_line + l_size, bytes + z_gap_end, cont_l_size
          text_ptr = gap_line
          l_size += cont_l_size

      -- break if we're not advancing - unless the last char scanned
      -- was an end-of-line character or the absolute first line
      -- in those cases we still want the line represented
      break if next_p == offset and not (last_was_eol or nr == 0)

      nr += 1
      end_offset = max next_p - base_offset, start_p + 1

      lines[nr] = setmetatable {
        :nr
        ptr: text_ptr
        size: l_size
        full_size: end_offset - (start_p + 1) + 1
        start_offset: start_p + 1
        :end_offset
        has_eol: was_eol
      }, LineMt

      offset = next_p
      last_was_eol = was_eol

    @_last_scanned_line = max(nr, @_last_scanned_line)

  _invalidate_lines_from_offset: (offset) =>
    if offset <= 1
      @_last_scanned_line = 0
      @_lines = {}
    else
      for i = 1, @_last_scanned_line
        line = @_lines[i]
        if line.end_offset >= offset or not line.has_eol
          for j = i, @_last_scanned_line
            @_lines[j] = nil

          @_last_scanned_line = line.nr - 1
          break

  _on_modification: (type, offset, text, size, invalidate_offset) =>
    revision = @revisions\push(type, offset, text)

    args = :offset, :text, :size, :invalidate_offset, :revision
    contains_newlines = text\find('[\n\r]') != nil

    if @lexer
      at_line = @get_line_at_offset(offset)
      if at_line -- else at eof
        last_line_shown = at_line.nr
        for listener in *@listeners
          if listener.last_line_shown
            last_line_shown = max last_line_shown, listener.last_line_shown!

        style_to = min(last_line_shown + 20, @nr_lines)
        args.styled = @refresh_styling_at at_line.nr, style_to, {
          force_full: contains_newlines
          no_notify: true
        }

    @notify type, args

  _on_style_changed: (_, start_offset, end_offset) =>
    start_line = @get_line_at_offset start_offset
    end_line = start_line
    if end_offset > start_line.end_offset and start_line.has_eol
      end_line = @get_line_at_offset end_offset

    styled = start_line: start_line.nr, end_line: end_line.nr, invalidated: false
    @notify('styled', styled)

}

define_class Buffer, {
  __tostring: (b) -> b\tostring!
}
