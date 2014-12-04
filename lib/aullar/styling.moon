-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:fill} = require 'ffi'
{:define_class} = require 'aullar.util'
GapBuffer = require 'aullar.gap_buffer'
append = table.insert
{:min, :max} = math

id_seq = 1
style_map = {}

style_id_for_name = (name) ->
  id = style_map[name]

  unless id
    id = id_seq
    id_seq += 1
    style_map[name] = id
    style_map[id] = name

  id

define_class {
  new: (size) =>
    @style_buffer = GapBuffer 'uint16_t', size
    @last_pos_styled = 0

  get: (start_offset, end_offset) =>
    return {} if start_offset > @last_pos_styled

    if start_offset <= 0 or end_offset < start_offset or end_offset > @style_buffer.size
      return {}

    spec = {}
    cur = 0
    sb = @style_buffer
    arr = sb.array
    offset = start_offset - 1
    offset += sb.gap_size if offset >= sb.gap_start
    i = 1

    while i <= (end_offset - start_offset) + 1

      if offset >= sb.gap_start and offset < sb.gap_end -- entering into gap
        offset += sb.gap_size

      style = arr[offset]
      if style != cur
        if cur > 0
          spec[#spec + 1] = i

        if style != 0
          spec[#spec + 1] = i
          spec[#spec + 1] = style_map[style]

        cur = style

      i += 1
      offset += 1

      if (start_offset + i - 1) > @last_pos_styled
        break

    if cur > 0
      spec[#spec + 1] = i

    spec

  set: (start_offset, end_offset, style) =>
    style_id = style_id_for_name style
    @style_buffer\fill start_offset - 1, end_offset - 1, style_id
    @last_pos_styled = max(@last_pos_styled, end_offset)

  clear: (start_offset, end_offset) =>
    @style_buffer\fill start_offset - 1, end_offset - 1, 0

  apply: (offset, styling, opts = {}) =>
    return if #styling == 0
    @_check_offsets offset

    sb = @style_buffer
    arr = sb.array
    base = offset - 1
    base_style = opts.base and "#{opts.base}:" or ''

    for s_idx = 1, #styling, 3
      styling_start = styling[s_idx]
      style = styling[s_idx + 1]
      continue if style == 'whitespace'

      if type(style) != 'table' -- normal lexing
        styling_end = styling[s_idx + 2]
        @set base + styling_start, base + styling_end - 1, base_style .. style

      else -- embedded styling (sub lexing)
        if #style > 0
          sub_base = styling[s_idx + 2]\match '[^|]*|(.+)'
          sub_start_offset = base + styling_start
          sub_end_offset = sub_start_offset + style[#style] - 1

          @set sub_start_offset, sub_end_offset - 1, sub_base
          @apply sub_start_offset, style, base: sub_base

    @last_pos_styled

  invalidate_from: (offset) =>
    @_check_offsets offset
    return if offset > @last_pos_styled
    @clear offset, @last_pos_styled
    @last_pos_styled = max(0, offset - 1)

  insert: (offset, count) =>
    @style_buffer\insert offset - 1, nil, count
    @last_pos_styled += count if offset <= @last_pos_styled

  delete: (offset, count) =>
    @style_buffer\delete offset - 1, count
    if offset <= @last_pos_styled
      style_positions_removed = min(@last_pos_styled - offset, count)
      @last_pos_styled -= style_positions_removed

  at: (offset) =>
    return nil if offset < 1 or offset > @style_buffer.size
    return nil if offset > @last_pos_styled
    ptr = @style_buffer\get_ptr(offset - 1, 1)
    style_map[ptr[0]]

  _check_offsets: (start_offset, end_offset) =>
    if start_offset <= 0 or start_offset > @style_buffer.size
      error "Styling: Illegal start_offset #{start_offset}", 3

    if end_offset and (end_offset <= 0 or end_offset > @style_buffer.size)
      error "Styling: Illegal end_offset #{end_offset}", 3
}
