-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C, ffi_string, ffi_copy = ffi.C, ffi.string, ffi.copy
{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Styling = require 'aullar.styling'
Offsets = require 'aullar.offsets'
GapBuffer = require 'aullar.gap_buffer'

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

Buffer = {
  new: (text = '') =>
    @listeners = {}
    @text = text
    @styling = Styling @
    @offsets = Offsets!

  properties: {
    size: => @gap_buffer.size

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
        size = #text
        @gap_buffer = GapBuffer 'char', size, initial: text
        @_last_scanned_line = 0
        @_lines = {}

        @_on_modification 'inserted', 1, text, size
    }
  }

  add_listener: (listener) =>
    @listeners[#@listeners + 1] = listener

  remove_listener: (listener) =>
    @listeners = [l for l in *@listeners when l != listener]

  insert: (offset, text, size = #text) =>
    @gap_buffer\insert offset - 1, text
    @_invalidate_lines_from_offset offset
    @offsets\invalidate_from offset - 1

    @_on_modification 'inserted', offset, text, size

  delete: (offset, count) =>
    text = @sub offset, offset + count - 1
    @gap_buffer\delete offset - 1, count
    @_invalidate_lines_from_offset offset
    @offsets\invalidate_from offset - 1

    @_on_modification 'deleted', offset, text, count

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
    @_scan_lines_to :line
    @_lines[line]

  get_line_at_offset: (offset) =>
    @_scan_lines_to :offset
    start_at, end_at, step = 1, @_last_scanned_line, 1
    last_line = @_lines[@_last_scanned_line]
    if last_line and abs(last_line.start_offset - offset) < offset
      start_at, end_at, step = last_line.nr, 1, -1

    for i = start_at, end_at, step
      line = @_lines[i]

      if offset >= line.start_offset and offset <= line.end_offset
        return line

    nil

  get_ptr: (offset, size) =>
    @gap_buffer\get_ptr offset - 1, size

  sub: (start_index, end_index) =>
    return '' if start_index > @size
    end_index or= @size
    end_index = @size if end_index > @size
    size = (end_index - start_index) + 1
    return '' if size == 0
    ffi_string(@get_ptr(start_index, size), size)

  style: (offset, styling) =>
    @styling\apply offset, styling

  tostring: =>
    @gap_buffer\compact! if @gap_buffer.gap_size != 0
    return ffi_string @gap_buffer.array, @gap_buffer.size

  ensure_styled_to: (line) =>
    return if @styling.last_line_styled >= line
    return unless @lexer
    @styling\style_to min(line + 20, @nr_lines), @lexer

  char_offset: (byte_offset) =>
    @gap_buffer\compact! if byte_offset > @gap_buffer.gap_start
    @offsets\char_offset(@gap_buffer.array, byte_offset - 1) + 1

  byte_offset: (char_offset) =>
    @gap_buffer\compact!
    @offsets\byte_offset(@gap_buffer.array, char_offset - 1) + 1

  notify: (event, parameters) =>
    for listener in *@listeners
      callback = listener["on_#{event}"]
      if callback
        status, ret = pcall callback, listener, @, parameters
        print "Error emitting '#{event}': #{ret}" unless status

  _scan_lines_to: (to) =>
    gb = @gap_buffer
    bytes = gb.array
    offset = 0
    base_offset = 0
    base = bytes
    nr = 0
    lines = @_lines
    size = gb.size
    bytes_size = size + gb.gap_size
    last_was_eol = false
    z_gap_start = gb.gap_start
    z_gap_end = gb.gap_end

    if @_last_scanned_line > 0
      with lines[@_last_scanned_line]
        offset = .end_offset
        nr = .nr
        last_was_eol = .has_eol

    stop_scan_at = bytes_size

    if offset >= z_gap_start
      base_offset += gb.gap_size
      offset += gb.gap_size
    else
      stop_scan_at = z_gap_start

    while (not to.line or nr < to.line) and (not to.offset or (offset - base_offset) < to.offset)
      text_ptr = base + offset
      start_p = offset - base_offset
      next_p, l_size, was_eol = scan_line base, offset, stop_scan_at

      if not was_eol and stop_scan_at != bytes_size -- at gap
        base_offset += gb.gap_size
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

      lines[nr] = {
        :nr
        text: text_ptr
        size: l_size
        full_size: end_offset - (start_p + 1) + 1
        start_offset: start_p + 1
        :end_offset
        has_eol: was_eol
      }
      offset = next_p
      last_was_eol = was_eol

    @_last_scanned_line = max(nr, @_last_scanned_line)

  _invalidate_lines_from_offset: (offset) =>
    if offset == 1
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

  _on_modification: (type, offset, text, size) =>
    args = :offset, :text, :size
    contains_newlines = text\find('[\n\r]') != nil

    if @lexer
      at_line = @get_line_at_offset(offset)
      if at_line -- else at eof
        last_line_shown = at_line.nr
        for listener in *@listeners
          if listener.last_line_shown
            last_line_shown = max last_line_shown, listener.last_line_shown!

        style_to = min(last_line_shown + 20, @nr_lines)
        args.styled = @styling\refresh_at at_line.nr, style_to, @lexer, {
          force_full: contains_newlines
          no_notify: true
        }

    @notify type, args
}

define_class Buffer, {
  __tostring: (b) -> b\tostring!
}

