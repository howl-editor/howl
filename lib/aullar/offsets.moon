-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)
--
-- This supports more efficient mappings of character (code points) <->
-- byte offsets for gap buffer contents, by caching offsets and thus
-- making scans shorter

ffi = require 'ffi'
bit = require 'bit'
require 'ljglibs.cdefs.glib'

tonumber, max, abs = tonumber, math.max, math.abs
C = ffi.C
band = bit.band

ffi.cdef [[
  struct ao_mapping {
    size_t c_offset;
    size_t b_offset;
  }
]]

NR_MAPPINGS = 20
IDX_LAST = NR_MAPPINGS - 1
MIN_SPAN_CHARS = 1000
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

gb_char_offset = (gb, start_offset, end_offset) ->
  idx = start_offset
  idx += gb.gap_size if idx >= gb.gap_start
  b_end = end_offset > gb.gap_start and (end_offset + gb.gap_size) or end_offset
  c_offset = 0
  p = gb.array

  while idx < b_end
    if idx >= gb.gap_start and idx < gb.gap_end
      idx += gb.gap_size

    idx = idx + 1
    while p[idx] != 0 and band(p[idx], 0xc0) == 0x80 -- continuation byte
      idx = idx + 1

    c_offset += 1

  c_offset

gb_byte_offset = (gb, start_offset, char_offset) ->
  idx = start_offset
  idx += gb.gap_size if idx >= gb.gap_start
  p = gb.array

  while char_offset > 0
    if idx >= gb.gap_start and idx < gb.gap_end
      idx += gb.gap_size

    idx += 1
    char_offset -= 1
    while p[idx] != 0 and band(p[idx], 0xc0) == 0x80 -- continuation byte
      idx += 1

  delta = idx >= gb.gap_end and gb.gap_size or 0
  (idx - start_offset) - delta

Offsets = {

  char_offset: (gb, byte_offset) =>
    m = mapping_for_byte @mappings, byte_offset

    -- should we create a new mapping, closer this offset?
    if (byte_offset - m.b_offset) > MIN_SPAN_BYTES and
      (gb.size - byte_offset) > MIN_SPAN_BYTES

      m_b_offset = byte_offset - (byte_offset % MIN_SPAN_BYTES)

      -- position may be in the middle of a sequence here, so back up as needed
      while m_b_offset > 0 and band(gb\get_ptr(m_b_offset, 1)[0], 0xc0) == 0x80
        m_b_offset -= 1

      c_offset = m.c_offset + gb_char_offset(gb, m.b_offset, m_b_offset)
      m = update_for @mappings, c_offset, m_b_offset

    tonumber m.c_offset + gb_char_offset(gb, m.b_offset, byte_offset)

  byte_offset: (gb, char_offset) =>
    m = mapping_for_char(@mappings, char_offset), char_offset

    -- should we create a new mapping, closer this offset?
    if char_offset - m.c_offset > MIN_SPAN_CHARS
      m_c_offset = char_offset - (char_offset % MIN_SPAN_CHARS)
      b_offset = m.b_offset + gb_byte_offset(gb, m.b_offset, m_c_offset - m.c_offset)
      m = update_for(@mappings, m_c_offset, b_offset)

    tonumber m.b_offset + gb_byte_offset(gb, m.b_offset, char_offset - m.c_offset)

  adjust_for_insert: (byte_offset, bytes, characters) =>
    mappings = @mappings
    for i = 0, IDX_LAST
      m = mappings[i]
      if m.c_offset != 0 and m.b_offset > byte_offset
        m.b_offset += bytes
        m.c_offset += characters

  adjust_for_delete: (byte_offset, bytes, characters) =>
    mappings = @mappings
    for i = 0, IDX_LAST
      m = mappings[i]
      if m.c_offset != 0 and m.b_offset > byte_offset
        -- update the mapping if we can
        if m.b_offset > bytes
          m.b_offset -= bytes
          m.c_offset -= characters
        else
          -- but if the result would wrap around we give up
          -- and invalidate all subsequent mapping
          @invalidate_from m.b_offset
          break

  invalidate_from: (byte_offset) =>
    mappings = @mappings
    for i = 0, IDX_LAST
      nm = mappings[i]
      nm.c_offset = 0 if nm.b_offset > byte_offset
}

-> setmetatable { mappings: ffi.new "struct ao_mapping[#{NR_MAPPINGS}]" }, __index: Offsets
