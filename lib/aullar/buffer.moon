-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C, ffi_string, ffi_copy = ffi.C, ffi.string, ffi.copy
{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Styling = require 'aullar.styling'

char_arr = ffi.typeof 'char [?]'
const_char_p = ffi.typeof 'const char *'
append = table.insert

ffi.cdef 'void *memmove(void *dest, const void *src, size_t n);'

GAP_SIZE = 100

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

  properties: {
    gap_size: => (@gap_end - @gap_start)

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
        @size = #text
        arr_size = @size + GAP_SIZE
        @bytes = char_arr(arr_size, text)
        @gap_start = @size + 1
        @gap_end = arr_size + 1
        @_last_scanned_line = 0
        @_lines = {}

        @_on_modification 'inserted', 1, text, @size
    }
  }

  add_listener: (listener) =>
    @listeners[#@listeners + 1] = listener

  remove_listener: (listener) =>
    @listeners = [l for l in *@listeners when l != listener]

  insert: (offset, text, size = #text) =>
    if size <= @gap_size
      @move_gap_to offset
    else
      @extend_gap_at offset, size + GAP_SIZE

    ffi_copy @bytes + @gap_start - 1, const_char_p(text), size
    @size += size
    @gap_start += size

    @_on_modification 'inserted', offset, text, size

  delete: (offset, count) =>
    text = @sub offset, offset + count - 1

    if offset + count == @gap_start -- adjust gap start backwards
      @gap_start -= count
      @_invalidate_lines_from_offset offset
    elseif offset == @gap_end - @gap_size -- adjust gap end forward
      @gap_end += count
      @_invalidate_lines_from_offset offset
    else
      @move_gap_to offset + count
      @gap_start -= count

    @size -= count
    @_on_modification 'deleted', offset, text, count

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
    if offset < 1 or offset > @size or (offset + size - 1) > @size or size < 0
      error "Buffer.get_ptr(): Illegal range: offset=#{offset}, size=#{size} for buffer of size #{@size}"

    if offset > @gap_start
      @bytes + @gap_size + offset - 1
    elseif (offset + size - 1) < @gap_start
      @bytes + offset - 1
    else
      arr = char_arr(size)
      pregap_size = @gap_start - offset
      ffi_copy arr, @bytes + offset - 1, pregap_size
      ffi_copy arr + pregap_size, @bytes + @gap_end - 1, size - pregap_size
      arr

  sub: (start_index, end_index) =>
    return '' if start_index > @size
    end_index or= @size
    end_index = @size if end_index > @size
    size = (end_index - start_index) + 1
    return '' if size == 0
    ffi_string(@get_ptr(start_index, size), size)

  style: (offset, styling) =>
    @styling\apply offset, styling

  move_gap_to: (offset) =>
    @_invalidate_lines_from_offset min(offset, @gap_start)

    b_offset = offset - 1

    if b_offset > @size
      b_offset = @size
    elseif offset < 0
      b_offset = 0

    delta = offset - @gap_start
    return if delta == 0
    base = @bytes

    if delta < 0 -- offset < gap start, move stuff up
      dest = base + (@gap_end - 1) + delta
      src = base + b_offset
      C.memmove dest, src, -delta

    else -- offset > gap start, move stuff down
      C.memmove base + (@gap_start - 1), base + (@gap_end - 1), delta

    gap_size = @gap_size
    @gap_start = offset
    @gap_end = offset + gap_size

  extend_gap_at: (offset, gap_size) =>
    @_invalidate_lines_from_offset 1

    arr_size = @size + gap_size
    arr = char_arr(arr_size)
    src_ptr = @bytes
    dest_ptr = arr

    -- chunk up to gap start or offset
    count = min(@gap_start, offset) - 1
    ffi_copy dest_ptr, src_ptr, count

    if @gap_start < offset -- fill from post gap
      src_ptr = @bytes + (@gap_end - 1)
      dest_ptr += count
      count = (offset - 1) - count
      ffi_copy dest_ptr, src_ptr, count

    -- now at dest post gap
    src_ptr += count
    dest_ptr = arr + (offset - 1) + gap_size

    if @gap_start > offset -- fill remainder from pre gap
      count = @gap_start - offset
      ffi_copy dest_ptr, src_ptr, count
      src_ptr = @bytes + (@gap_end - 1)
      dest_ptr += count

    -- the rest
    count = (arr + arr_size) - dest_ptr
    ffi_copy dest_ptr, src_ptr, count

    @bytes = arr
    @gap_start = offset
    @gap_end = offset + gap_size

  compact: =>
    @move_gap_to @size + 1

  tostring: =>
    @compact! if @gap_size != 0
    return ffi_string @bytes, @size

  ensure_styled_to: (line) =>
    return if @styling.last_line_styled >= line
    return unless @lexer
    @styling\style_to min(line + 20, @nr_lines), @lexer

  notify: (event, parameters) =>
    for listener in *@listeners
      callback = listener["on_#{event}"]
      if callback
        status, ret = pcall callback, listener, @, parameters
        print "Error emitting '#{event}': #{ret}" unless status

  _scan_lines_to: (to) =>
    bytes = @bytes
    base_offset = 0
    base = @bytes
    offset = 0
    nr = 0
    lines = @_lines
    size = @size
    bytes_size = @size + @gap_size
    last_was_eol = false
    z_gap_start = @gap_start - 1
    z_gap_end = @gap_end - 1

    if @_last_scanned_line > 0
      with lines[@_last_scanned_line]
        offset = .end_offset
        nr = .nr
        last_was_eol = .has_eol

    stop_scan_at = bytes_size

    if offset >= z_gap_start
      base_offset += @gap_size
      offset += @gap_size
    else
      stop_scan_at = z_gap_start

    while (not to.line or nr < to.line) and (not to.offset or (offset - base_offset) < to.offset)
      text_ptr = base + offset
      start_p = offset - base_offset
      next_p, l_size, was_eol = scan_line base, offset, stop_scan_at

      if not was_eol and stop_scan_at != bytes_size -- at gap
        base_offset += @gap_size
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

