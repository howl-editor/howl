-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
{:define_class} = require 'aullar.util'
append = table.insert
{:min, :max} = math

ffi.cdef [[
  typedef struct {
    int size;
    uint16_t arr[?];
  } aullar_styling;
]]

aullar_styling_t = ffi.typeof 'aullar_styling'
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

get_line_styling = (arr, line) ->
  styling = arr[line.nr]
  unless styling
    styling = aullar_styling_t line.full_size, line.full_size
    arr[line.nr] = styling

  styling

translate_styling = (line_styling) ->
  return {} unless line_styling
  spec = {}
  cur = 0
  arr = line_styling.arr

  for i = 0, line_styling.size - 1
    style = arr[i]
    if style != cur
      if cur > 0
        spec[#spec + 1] = i + 1

      if style != 0
        spec[#spec + 1] = i + 1
        spec[#spec + 1] = style_map[style]

      cur = style

  if cur > 0
    spec[#spec + 1] = line_styling.size + 1

  spec

define_class {
  new: (@buffer) =>
    @_line_stylings = {}
    @lines = setmetatable {}, __index: (_, k) ->
      translate_styling @_line_stylings[k]
    @last_line_styled = 0

  set: (start_offset, end_offset, style) =>
    line = @buffer\get_line_at_offset start_offset
    error "Invalid offset #{start_offset} passed to set()", 2 unless line
    base_offset = start_offset - line.start_offset
    style_id = style_id_for_name style

    while line and line.start_offset < end_offset
      start_i = max(0, start_offset - line.start_offset)
      end_i = min(line.full_size, end_offset - line.start_offset)
      line_styling = get_line_styling(@_line_stylings, line)
      assert(end_i <= line_styling.size, "Styling#set #{end_i} at #{line.nr}: Out of sync")
      for i = start_i, end_i - 1
        line_styling.arr[i] = style_id

      @last_line_styled = max @last_line_styled, line.nr
      line = @buffer\get_line(line.nr + 1)

  apply: (offset, styling, opts = {}) =>
    line = @buffer\get_line_at_offset offset
    error "Invalid offset #{offset} passed to style()", 2 unless line

    line_offset = offset - line.start_offset
    base_offset = line_offset
    line_styling = get_line_styling(@_line_stylings, line)
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
          line_styling = get_line_styling(@_line_stylings, line)

        styling_start_line = (styling_start + line_offset) - 1 -- zero based

        if type(style) != 'table' -- normal lexing
          styling_end_line = (styling[i + 2] + line_offset) - 1 -- zero based
          end_styling_at = min styling_end_line, line.full_size
          style_id = style_id_for_name base_style .. style

          assert(end_styling_at <= line_styling.size, "Styling.apply #{end_styling_at} at line #{line.nr}: Out of sync")
          for i = styling_start_line, end_styling_at - 1
            line_styling.arr[i] = style_id

          if styling_end_line != end_styling_at -- styling extends over eol
            -- keep styling from first column of next line
            styling_start = (line.end_offset + 1) - offset + 1
          else
            styling_start = nil

          @last_line_styled = max @last_line_styled, line.nr

        else -- embedded styling (sub lexing)
          sub_base = styling[i + 2]\match '[^|]*|(.+)'
          if #style > 0
            sub_start_offset = styling_start + offset - 1
            sub_end_offset = sub_start_offset + style[#style] - 1
            @set sub_start_offset, sub_end_offset, sub_base
            @apply styling_start + offset - 1, style, base: sub_base

          styling_start = nil


  invalidate_from: (line) =>
    for nr = line, @last_line_styled
      @_line_stylings[nr] = nil

    @last_line_styled = line - 1

  at: (line, col) =>
    line_styling = @_line_stylings[line]
    if line_styling
      col = line_styling.size + col + 1 if col < 0
      if col > 0 and col <= line_styling.size
        return style_map[line_styling.arr[col - 1]]

    nil

  style_to: (to_line, lexer, opts = {}) =>
    return unless to_line > @last_line_styled
    start_line_nr = @last_line_styled + 1
    opts = moon.copy opts
    opts.force_full = true
    @refresh_at start_line_nr, to_line, lexer, opts

  refresh_at: (line_nr, to_line, lexer, opts = {}) =>
    at_line = @buffer\get_line(line_nr)
    return unless at_line

    start_line = min at_line.nr, @last_line_styled + 1

    -- find the starting line to lex from
    while start_line > 1
      prev_eol_style = @at start_line - 1, -1
      break if not prev_eol_style or prev_eol_style == 'whitespace'
      start_line -= 1

    start_offset = @buffer\get_line(start_line).start_offset
    at_line_eol_style = @at(at_line.nr, -1) or 'whitespace'

    for i = start_line, at_line.nr
      @_line_stylings[i] = nil

    styled = nil

    if not opts.force_full
      -- try lexing only up to this line
      text = @buffer\sub start_offset, at_line.end_offset
      @apply start_offset, lexer(text)
      new_at_line_eol_style = @at(at_line.nr, -1) or 'whitespace'
      if new_at_line_eol_style == at_line_eol_style
        styled = start_line: at_line.nr, end_line: at_line.nr, invalidated: false

    unless styled
      @invalidate_from at_line.nr
      end_line = @buffer\get_line(to_line) or @buffer\get_line(@buffer.nr_lines)
      text = @buffer\sub start_offset, end_line.end_offset
      @apply start_offset, lexer(text)
      @last_line_styled = end_line.nr
      styled = start_line: at_line.nr, end_line: end_line.nr, invalidated: true

    @buffer\notify('styled', styled) unless opts.no_notify
    styled
}
