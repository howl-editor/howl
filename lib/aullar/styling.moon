-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
{:define_class} = require 'aullar.util'
append = table.insert
{:fill, :sizeof} = ffi
{:min, :max} = math

style_arr_t = ffi.typeof 'uint16_t[?]'
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

style_arr = (arr, line) ->
  styling = arr[line.nr]
  unless styling
    styling = style_arr_t line.full_size
    arr[line.nr] = styling

  styling

translate_styling = (arr) ->
  return {} unless arr
  spec = {}
  cur = 0
  size = (sizeof(arr) / 2)

  for i = 0, size - 1
    style = arr[i]
    if style != cur
      if cur > 0
        spec[#spec + 1] = i + 1

      if style != 0
        spec[#spec + 1] = i + 1
        spec[#spec + 1] = style_map[style]

      cur = style

  if cur > 0
    spec[#spec + 1] = size + 1

  spec

define_class {
  new: (@buffer) =>
    @_arrays = {}
    @lines = setmetatable {}, __index: (_, k) -> translate_styling @_arrays[k]

  set: (start_offset, end_offset, style) =>
    line = @buffer\get_line_at_offset start_offset
    error "Invalid offset #{start_offset} passed to set()", 2 unless line
    base_offset = start_offset - line.start_offset
    style_id = style_id_for_name style

    while line and line.start_offset < end_offset
      start_i = max(0, start_offset - line.start_offset)
      end_i = min(line.full_size, end_offset - line.start_offset)
      line_style_arr = style_arr(@_arrays, line)
      for i = start_i, end_i - 1
        line_style_arr[i] = style_id

      line = @buffer\get_line(line.nr + 1)

  apply: (offset, styling, opts = {}) =>
    line = @buffer\get_line_at_offset offset
    error "Invalid offset #{offset} passed to style()", 2 unless line

    line_offset = offset - line.start_offset
    base_offset = line_offset
    line_style_arr = style_arr(@_arrays, line)
    base_style = opts.base and "#{opts.base}:" or ''

    for i = 1, #styling, 3
      styling_start = styling[i]
      style = styling[i + 1]
      continue if style == 'whitespace'

      while styling_start

        if line.end_offset < styling_start + offset - 1 -- entering a new line
          while line and line.end_offset < styling_start + offset - 1
            line = @buffer\get_line(line.nr + 1)

          return unless line
          line_offset = offset - line.start_offset
          last_styled = 0
          line_style_arr = style_arr(@_arrays, line)

        styling_start_line = (styling_start + line_offset) - 1 -- zero based

        if type(style) != 'table' -- normal lexing
          styling_end_line = (styling[i + 2] + line_offset) - 1 -- zero based
          end_styling_at = min styling_end_line, line.full_size
          style_id = style_id_for_name base_style .. style

          for i = styling_start_line, end_styling_at - 1
            line_style_arr[i] = style_id

          if styling_end_line != end_styling_at -- styling extends over eol
            -- keep styling from first column of next line
            styling_start = (line.end_offset + 1) - base_offset
          else
            styling_start = nil

        else -- embedded styling (sub lexing)
          sub_base = styling[i + 2]\match '[^|]*|(.+)'
          if #style > 0
            sub_start_offset = styling_start + offset - 1
            sub_end_offset = sub_start_offset + style[#style] - 1
            @set sub_start_offset, sub_end_offset, sub_base
            @apply styling_start + offset - 1, style, base: sub_base

          styling_start = nil
}
