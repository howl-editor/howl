-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C, ffi_string, ffi_copy = ffi.C, ffi.string, ffi.copy
{:max, :min, :abs} = math
{:Object} = require 'aullar.util'

char_arr = ffi.typeof 'char [?]'
const_char_p = ffi.typeof 'const char *'

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
    if eol_byte == 13
      byte = base[offset]
      if byte == 10
        offset += 1

  offset, l_size, was_eol


Buffer = {
  new: (text) ->
    size = #text
    arr_size = size + GAP_SIZE
    {
      bytes: char_arr(arr_size, text),
      :size,
      gap_start: size,
      gap_end: arr_size,
      _last_scanned_line: 0,
      _lines: {}
    }

  properties: {
    gap_size: => (@gap_end - @gap_start)

    nr_lines: =>
      @_scan_lines_to {}
      @_last_scanned_line
  }

  insert: (offset, text, size = #text) =>
    @_invalidate_lines_from_offset offset

    if size <= @gap_size
      @move_gap_to offset
    else
      @extend_gap_at offset, size + GAP_SIZE

    ffi_copy @bytes + @gap_start, const_char_p(text), size
    @size += size
    @gap_start += size

  delete: (offset, count) =>
    @_invalidate_lines_from_offset offset

    if offset + count == @gap_start -- adjust gap start backwards
      @gap_start -= count
    elseif offset == @gap_end - @gap_size -- adjust gap end forward
      @gap_end += count
    else
      @move_gap_to offset + count
      @gap_start -= count

    @size -= count

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
        -- print "scanned: #{abs(i - start_at)}"
        return line

    nil

  get_ptr: (offset, size) =>
    if offset < 0 or offset >= @size or offset + size > @size or size < 0
      error "Illegal range: offset=#{offset}, size=#{size} for buffer of size #{@size}"

    if offset > @gap_start
      @bytes + @gap_size + offset
    elseif size < @gap_start
      @bytes + offset
    else
      arr = char_arr(size)
      pregap_size = @gap_start - offset
      ffi_copy arr, @bytes + offset, pregap_size
      ffi_copy arr + pregap_size, @bytes + @gap_end, size - pregap_size
      arr

  move_gap_to: (offset) =>
    if offset > @size
      offset = @size
    elseif offset < 0
      offset = 0

    delta = offset - @gap_start
    return if delta == 0
    base = @bytes

    if delta < 0 -- offset < gap start, move stuff up
      dest = base + @gap_end + delta
      src = base + offset
      C.memmove dest, src, -delta

    else -- offset > gap start, move stuff down
      C.memmove base + @gap_start, base + @gap_end, delta

    gap_size = @gap_size
    @gap_start = offset
    @gap_end = offset + gap_size

  extend_gap_at: (offset, gap_size) =>
    arr_size = @size + gap_size
    arr = char_arr(arr_size, string.rep('x', arr_size))
    src_ptr = @bytes
    dest_ptr = arr

    -- chunk up to gap start or offset
    count = min @gap_start, offset
    ffi_copy dest_ptr, src_ptr, count

    if @gap_start < offset -- fill from post gap
      src_ptr = @bytes + @gap_end
      dest_ptr += count
      count = offset - count
      ffi_copy dest_ptr, src_ptr, count

    -- now at dest post gap
    src_ptr += count
    dest_ptr = arr + offset + gap_size

    if @gap_start > offset -- fill remainder from pre gap
      count = @gap_start - offset
      ffi_copy dest_ptr, src_ptr, count
      src_ptr = @bytes + @gap_end
      dest_ptr += count

    -- the rest
    count = (arr + arr_size) - dest_ptr
    ffi_copy dest_ptr, src_ptr, count

    @bytes = arr
    @gap_start = offset
    @gap_end = offset + gap_size

  compact: =>
    @move_gap_to @size

  tostring: =>
    @compact! if @gap_size != 0
    return ffi_string @bytes, @size

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

    if @_last_scanned_line > 0
      with lines[@_last_scanned_line]
        offset = .end_offset + 1
        nr = .nr
        last_was_eol = .has_eol

    stop_scan_at = bytes_size

    if offset >= @gap_start
      base_offset += @gap_size
      offset += @gap_size
    else
      stop_scan_at = @gap_start

    while (not to.line or nr < to.line) and (not to.offset or (offset - base_offset) <= to.offset)
      text_ptr = base + offset
      start_p = offset - base_offset
      next_p, l_size, was_eol = scan_line base, offset, stop_scan_at

      if not was_eol and stop_scan_at != bytes_size -- at gap
        base_offset += @gap_size
        stop_scan_at = bytes_size
        next_p, cont_l_size, was_eol = scan_line bytes, @gap_end, stop_scan_at
        if cont_l_size > 0 -- else gap is at end, nothing left
          gap_line = char_arr(l_size + cont_l_size)
          ffi_copy gap_line, text_ptr, l_size
          ffi_copy gap_line + l_size, bytes + @gap_end, cont_l_size
          text_ptr = gap_line
          l_size += cont_l_size

      break if next_p == offset and not last_was_eol

      nr += 1

      lines[nr] = {
        :nr
        text: text_ptr
        size: l_size
        start_offset: start_p
        end_offset: (next_p - base_offset) - 1
        has_eol: was_eol
      }
      offset = next_p
      last_was_eol = was_eol

    @_last_scanned_line = max(nr, @_last_scanned_line)

  _invalidate_lines_from_offset: (offset) =>
    for i = 1, @_last_scanned_line
      line = @_lines[i]
      if line.end_offset >= offset or not line.has_eol
        @_last_scanned_line = line.nr - 1
        break

}

(...) -> Object Buffer.new(...), Buffer, {
  __tostring: (b) -> b\tostring!
}
