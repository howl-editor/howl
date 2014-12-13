-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)
--
-- This supports efficient mappings of character (code points) <->
-- byte offsets for buffer contents

ffi = require 'ffi'
bit = require 'bit'

tonumber, max, abs = tonumber, math.max, math.abs
C = ffi.C
band = bit.band

ffi.cdef [[
  struct ao_mapping {
    long c_offset;
    long b_offset;
  }
]]

NR_MAPPINGS = 10
IDX_LAST = NR_MAPPINGS - 1
MIN_SPAN = 1000
MIN_SPAN_BYTES = 1500
zero_mapping = ffi.new 'struct ao_mapping'

mapping_for_char = (mappings, char_offset) ->
  m = zero_mapping
  idx = 0
  for i = 0, IDX_LAST
    idx = i
    nm = mappings[i]
    break if nm.c_offset == 0 or nm.c_offset > char_offset
    m = nm

  m

mapping_for_byte = (mappings, byte_offset) ->
  m = zero_mapping
  idx = 0
  for i = 0, IDX_LAST
    idx = i
    nm = mappings[i]
    break if nm.c_offset == 0 or nm.b_offset > byte_offset
    m = nm

  m

update_for = (mappings, char_offset, byte_offset) ->
  idx = 0
  for i = 0, IDX_LAST
    nm = mappings[i]
    return nm if nm.c_offset == char_offset -- already present
    break if nm.c_offset == 0
    break if nm.c_offset > char_offset
    idx = i + 1

  if idx == NR_MAPPINGS -- rebalancing time
    idx = NR_MAPPINGS / 2
    for i = idx + 1, IDX_LAST
      mappings[i].c_offset = 0

  m = mappings[idx]
  m.c_offset = char_offset
  m.b_offset = byte_offset
  m

pointer_to_offset = (p, p_end) ->
  count = p_end - p
  i = 0
  offset = 0

  while i < count
    i = i + 1
    while p[i] ~= 0 and band(p[i], 0xc0) == 0x80 -- continuation byte
      i = i + 1

    offset = offset + 1

  offset

offset_to_pointer = (p, offset) ->
  while offset > 0
    p += 1
    while p[0] != 0 and band(p[0], 0xc0) == 0x80
      p += 1

    offset -= 1

  p

Offsets = {
  :pointer_to_offset

  char_offset: (ptr, byte_offset) =>
    mappings = @mappings
    m = mapping_for_byte mappings, byte_offset
    p = ptr + m.b_offset

    if (byte_offset - m.b_offset) > MIN_SPAN_BYTES
      m_offset_ptr = (ptr + byte_offset) - MIN_SPAN_BYTES
      m_byte_offset = byte_offset

      -- position may be in the middle of a sequence here, so back up as needed
      while m_offset_ptr != p and band(m_offset_ptr[0], 0xc0) == 0x80
        m_offset_ptr -= 1
        m_byte_offset -= 1

      c_offset = m.c_offset + pointer_to_offset(p, m_offset_ptr)
      m = update_for mappings, c_offset, m_byte_offset - MIN_SPAN_BYTES
      p = m_offset_ptr

    offset_ptr = ptr + byte_offset
    m.c_offset + pointer_to_offset(p, offset_ptr)

  byte_offset: (ptr, char_offset) =>
    mappings = @mappings
    m = mapping_for_char mappings, char_offset
    p = ptr + m.b_offset

    if char_offset - m.c_offset > MIN_SPAN
      span_offset = char_offset - (char_offset % MIN_SPAN)
      next_ptr = offset_to_pointer(p, span_offset - m.c_offset)
      n = tonumber (next_ptr - p) + m.b_offset
      m = update_for mappings, span_offset, n
      p = ptr + m.b_offset

    next_ptr = offset_to_pointer(p, char_offset - m.c_offset)
    tonumber (next_ptr - p) + m.b_offset

  invalidate_from: (byte_offset) =>
    mappings = @mappings
    for i = 0, IDX_LAST
      nm = mappings[i]
      nm.c_offset = 0 if nm.b_offset > byte_offset
}

-> setmetatable { mappings: ffi.new "struct ao_mapping[#{NR_MAPPINGS}]" }, __index: Offsets
