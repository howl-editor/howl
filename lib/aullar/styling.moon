-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:fill} = require 'ffi'
{:define_class} = require 'aullar.util'
GapBuffer = require 'aullar.gap_buffer'
Markers = require 'aullar.markers'
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

get_sub_style_end = (sub_start_offset, styling) ->
  for i = #styling, 3, -3
    e = styling[i]
    if type(e) != 'string'
      return sub_start_offset + e - 1
    else
      sub_end = get_sub_style_end sub_start_offset + styling[i - 2] - 1, styling[i - 1]
      return sub_end if sub_end

define_class {
  new: (size, @listener) =>
    @style_buffer = GapBuffer 'uint16_t', size
    @last_pos_styled = 0
    @sub_style_markers = Markers!

  reset: (size) =>
    @style_buffer\set nil, size
    @sub_style_markers = Markers!
    @last_pos_styled = 0

  sub: (styling, start_offset, end_offset) ->
    styles = {}

    for i = 1, #styling - 1, 3
      s_offset = styling[i]
      s_name = styling[i + 1]
      e_offset = styling[i + 2]
      break if s_offset >= end_offset -- we're past our section of interest
      if e_offset > start_offset
        append styles, max(s_offset, start_offset) - start_offset + 1
        append styles, s_name
        append styles, min(e_offset, end_offset) - start_offset + 1

    styles

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

  set: (start_offset, end_offset, style, opts = {}) =>
    style_id = style_id_for_name style
    @style_buffer\fill start_offset - 1, end_offset - 1, style_id
    @last_pos_styled = max(@last_pos_styled, end_offset)
    @_notify(start_offset, end_offset) unless opts.no_notify

  clear: (start_offset, end_offset, opts = {}) =>
    @sub_style_markers\remove_for_range start_offset, end_offset
    @style_buffer\fill start_offset - 1, end_offset - 1, 0
    @_notify(start_offset, end_offset) unless opts.no_notify

  apply: (offset, styling, opts = {}) =>
    return if #styling == 0
    @_check_offsets offset

    sb = @style_buffer
    arr = sb.array
    base = offset - 1
    base_style = opts.base and "#{opts.base}:" or ''
    no_notify = no_notify: true
    styled_up_to = 1

    markers = opts.markers or {}

    for s_idx = 1, #styling, 3
      styling_start = styling[s_idx]
      style = styling[s_idx + 1]
      continue if style == 'whitespace'

      if type(style) != 'table' -- normal lexing
        styling_end = styling[s_idx + 2]
        styled_up_to = base + styling_end - 1
        @set base + styling_start, styled_up_to, base_style .. style, no_notify

      else -- embedded styling (sub lexing)
        if #style > 0
          mode_name, sub_base = styling[s_idx + 2]\match '([^|]*)|(.+)'
          sub_start_offset = base + styling_start

          -- determine sub styling end, so we can fill it with base
          sub_end_offset = get_sub_style_end sub_start_offset, style
          if sub_end_offset -- no sub_end_offset == empty nested styling blocks
            @set sub_start_offset, sub_end_offset - 1, sub_base, no_notify
            @apply sub_start_offset, style, base: sub_base, no_notify: true, :markers
            styled_up_to = sub_end_offset
            append markers,
              name: mode_name
              start_offset: sub_start_offset
              end_offset: sub_end_offset + 1

    styled_from = offset + styling[1] - 1

    if not opts.markers
      @sub_style_markers\remove_for_range styled_from, styled_up_to
      @sub_style_markers\add markers

    @_notify(styled_from, styled_up_to) unless opts.no_notify
    styled_up_to

  invalidate_from: (offset, opts = {}) =>
    @_check_offsets offset
    return if offset > @last_pos_styled
    @clear offset, @last_pos_styled, no_notify: true
    @sub_style_markers\remove_for_range offset, @last_pos_styled
    last_pos_styled = @last_pos_styled
    @last_pos_styled = max(0, offset - 1)
    @_notify(offset, last_pos_styled) unless opts.no_notify

  insert: (offset, count, opts = {}) =>
    @style_buffer\insert offset - 1, nil, count
    @last_pos_styled += count if offset <= @last_pos_styled
    @_notify(offset, offset + count - 1) unless opts.no_notify

  delete: (offset, count, opts = {}) =>
    @style_buffer\delete offset - 1, count
    @sub_style_markers\remove_for_range offset, offset + count
    if offset <= @last_pos_styled
      style_positions_removed = min(@last_pos_styled - offset, count)
      @last_pos_styled -= style_positions_removed

      unless opts.no_notify
        @_notify(offset, offset + style_positions_removed - 1)

  at: (offset) =>
    return nil if offset < 1 or offset > @style_buffer.size
    return nil if offset > @last_pos_styled
    ptr = @style_buffer\get_ptr(offset - 1, 1)
    style_map[ptr[0]]

  get_mode_name_at: (pos) =>
    found = @sub_style_markers\at pos
    found and found[#found] and found[#found].name

  _notify: (start_offset, end_offset) =>
    if @listener and @listener.on_changed
      @listener\on_changed start_offset, end_offset

  _check_offsets: (start_offset, end_offset) =>
    if start_offset <= 0 or start_offset > @style_buffer.size
      error "Styling: Illegal start_offset #{start_offset}", 3

    if end_offset and (end_offset <= 0 or end_offset > @style_buffer.size)
      error "Styling: Illegal end_offset #{end_offset}", 3
}
