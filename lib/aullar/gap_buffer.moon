-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
C, ffi_copy, ffi_fill, ffi_gc, ffi_cast = ffi.C, ffi.copy, ffi.fill, ffi.gc, ffi.cast
{:min} = math
{:define_class} = require 'aullar.util'

ffi.cdef [[
  void *calloc(size_t nmemb, size_t size);
  void free(void *ptr);
  void *memmove(void *dest, const void *src, size_t n);
]]

GAP_SIZE = 100

define_class {
  new: (@type, size, opts = {}) =>
    @default_gap_size = opts.gap_size or GAP_SIZE
    @type_size = ffi.sizeof type
    @arr_ptr = ffi.typeof "const #{type} *"
    @new_arr = (arr_size) ->
      ffi_gc(ffi_cast("#{@type} *", C.g_malloc0(arr_size * @type_size)), C.g_free)

    @set opts.initial, size

  properties: {
    gap_size: => (@gap_end - @gap_start)
  }

  get_ptr: (offset, size) =>
    if offset < 0 or offset > (@size - 1) or (offset + size) > @size or size < 0
      error "GapBuffer.get_ptr(): Illegal range: offset=#{offset}, size=#{size} for buffer of size #{@size}", 2

    if offset >= @gap_start -- post gap ptr
      @array + @gap_size + offset, false
    elseif offset + size <= @gap_start -- pre gap ptr
      @array + offset, false
    else -- ephemeral copy pointer
      if size == @size
        @compact!
        @get_ptr(offset, size), true
      else
        arr = self.new_arr(size + 1)
        pregap_size = @gap_start - offset
        postgap_size = size - pregap_size
        ffi_copy arr, @array + offset, pregap_size * @type_size
        ffi_copy arr + pregap_size, @array + @gap_end, postgap_size * @type_size
        arr[size] = 0
        arr, false

  move_gap_to: (offset) =>
    if offset < 0 or offset > @size
      error "GapBuffer#move_gap_to: Illegal offset #{offset} (size #{@size})", 2

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
    ffi_fill @array + @gap_start, @gap_size * @type_size

  extend_gap_at: (offset, gap_size) =>
    if offset < 0 or offset > @size
      error "GapBuffer#extend_gap_at: Illegal offset #{offset} (size #{@size})", 2

    arr_size = @size + gap_size
    arr = self.new_arr arr_size
    src_ptr = @array
    dest_ptr = arr

    -- chunk up to gap start or offset
    count = min(tonumber(@gap_start), tonumber(offset))
    ffi_copy dest_ptr, src_ptr, count * @type_size

    -- fill from current post gap if the new gap is above the old
    if @gap_start < offset
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
    elseif @gap_start == offset
      src_ptr = @array + @gap_end

    -- the rest
    count = (arr + arr_size) - dest_ptr
    if count > 0
      ffi_copy dest_ptr, src_ptr, count * @type_size

    @array = arr
    @gap_start = offset
    @gap_end = offset + gap_size

  compact: =>
    @move_gap_to @size

  insert: (offset, data, size = #data) =>
    return if size == 0
    if offset < 0 or offset > @size
      error "GapBuffer#insert: Illegal offset #{offset} (size #{@size})", 2

    if size <= @gap_size
      @move_gap_to offset
    else
      @extend_gap_at offset, size + @default_gap_size

    if data
      ffi_copy @array + @gap_start, self.arr_ptr(data), size * @type_size
    else
      ffi_fill @array + @gap_start, size * @type_size

    @size += size
    @gap_start += size

  delete: (offset, count) =>
    return if count == 0 or offset >= @size

    if offset == @gap_end - @gap_size -- adjust gap end forward
      ffi_fill @array + @gap_end, count * @type_size -- zero fill
      @gap_end += count
    else
      if offset + count == @gap_start -- adjust gap start backwards
        @gap_start -= count
      else
        @move_gap_to offset + count
        @gap_start -= count

      ffi_fill @array + @gap_start, count * @type_size -- zero fill

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
    arr_size = size + @default_gap_size
    if @array and @size + @gap_size >= arr_size
      arr_size = @size + @gap_size
      ffi_fill @array, size * @type_size
    else
      -- allocate new array
      @array = self.new_arr(arr_size + 1) -- + 1 = with one final zero
      @array[arr_size] = 0 -- which we set here

    if data
      ffi_copy @array, data, size * @type_size
    @size = size
    @gap_start = size
    @gap_end = arr_size
    ffi_fill @array + @gap_start, @gap_size * @type_size
}
