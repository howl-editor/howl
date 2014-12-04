-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C, ffi_copy, ffi_fill = ffi.C, ffi.copy, ffi.fill
{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'

ffi.cdef 'void *memmove(void *dest, const void *src, size_t n);'

GAP_SIZE = 100

define_class {
  new: (@type, size, opts = {}) =>
    initial = opts.initial or 0
    @type_size = ffi.sizeof @type
    @new_arr = ffi.typeof "#{@type}[?]"
    @arr_ptr = ffi.typeof "const #{@type} *"
    @set initial, size

  properties: {
    gap_size: => (@gap_end - @gap_start)
  }

  get_ptr: (offset, size) =>
    if offset < 0 or offset > (@size - 1) or (offset + size) > @size or size < 0
      error "GapBuffer.get_ptr(): Illegal range: offset=#{offset}, size=#{size} for buffer of size #{@size}"

    if offset > @gap_start -- post gap ptr
      @array + @gap_size + offset
    elseif offset + size <= @gap_start -- pre gap ptr
      @array + offset
    else -- ephemeral copy pointer
      arr = self.new_arr(size)
      pregap_size = @gap_start - offset
      postgap_size = size - pregap_size
      ffi_copy arr, @array + offset, pregap_size * @type_size
      ffi_copy arr + pregap_size, @array + @gap_end, postgap_size * @type_size
      arr

  move_gap_to: (offset) =>
    if offset > @size
      offset = @size
    elseif offset < 0
      offset = 0

    delta = offset - @gap_start
    return if delta == 0

    if delta < 0 -- offset < gap start, move stuff up
      dest = @array + @gap_end + delta
      src = @array + offset
      C.memmove dest, src, (-delta) * @type_size

    else -- offset > gap start, move stuff down
      C.memmove @array + @gap_start, @array + @gap_end, delta * @type_size

    gap_size = @gap_size
    @gap_start = offset
    @gap_end = offset + gap_size

  extend_gap_at: (offset, gap_size) =>
    arr_size = @size + gap_size
    arr = self.new_arr arr_size
    src_ptr = @array
    dest_ptr = arr

    -- chunk up to gap start or offset
    count = min(@gap_start, offset)
    ffi_copy dest_ptr, src_ptr, count * @type_size

    if @gap_start < offset -- fill from post gap
      src_ptr = @array + @gap_end
      dest_ptr += count
      count = offset - count
      ffi_copy dest_ptr, src_ptr, count * @type_size

    -- now at dest post gap
    src_ptr += count
    dest_ptr = arr + offset + gap_size

    if @gap_start > offset -- fill remainder from pre gap
      count = @gap_start - offset
      ffi_copy dest_ptr, src_ptr, count * @type_size
      src_ptr = @array + @gap_end
      dest_ptr += count

    -- the rest
    count = (arr + arr_size) - dest_ptr
    ffi_copy dest_ptr, src_ptr, count * @type_size

    @array = arr
    @gap_start = offset
    @gap_end = offset + gap_size

  compact: =>
    @move_gap_to @size + 1

  insert: (offset, data, size = #data) =>
    if size <= @gap_size
      @move_gap_to offset
    else
      @extend_gap_at offset, size + GAP_SIZE

    if data
      ffi_copy @array + @gap_start, self.arr_ptr(data), size * @type_size
    else
      ffi_fill @array + @gap_start, size * @type_size

    @size += size
    @gap_start += size

  delete: (offset, count) =>
    if offset + count == @gap_start -- adjust gap start backwards
      @gap_start -= count
    elseif offset == @gap_end - @gap_size -- adjust gap end forward
      @gap_end += count
    else
      @move_gap_to offset + count
      @gap_start -= count

    @size -= count

  replace: (offset, count, replacement, replacement_size = #replacement) =>
    @delete offset, count
    @insert offset, replacement, replacement_size

  fill: (start_offset, end_offset, val) =>
    if start_offset < 0 or start_offset >= @size or end_offset >= @size
      error "GapBuffer#fill(#{start_offset}, #{end_offset}): Illegal offsets (size #{@size})", 2

    arr = @array
    i = start_offset
    offset = start_offset
    offset += @gap_size if offset >= @gap_start

    while i <= end_offset
      if offset >= @gap_start and offset < @gap_end -- entering into gap
        offset += @gap_size

      arr[offset] = val
      i += 1
      offset += 1

  set: (data, size = #data) =>
    arr_size = size + GAP_SIZE
    @array = self.new_arr(arr_size, data)
    @size = size
    @gap_start = size
    @gap_end = arr_size
}
