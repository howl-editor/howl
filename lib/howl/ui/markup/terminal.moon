-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
bit = require 'bit'
import const_char_p, char_arr from howl.cdefs
import StyledText, style from howl.ui

band = bit.band
append = table.insert

backspace = 8
escape = 27
left_bracket = 91
set_graphics_op = 109

ansi_colors = {
  'black',
  'red',
  'green',
  'yellow',
  'blue',
  'magenta',
  'cyan',
  'white'
}

define_style = (name, state) ->
  def = {
    underline: state.underline
    font: {
      italic: state.italic
      bold: state.bold
    }
  }
  if state.fg
    def.color = style[state.fg].color

  if state.bg
    def.background = style[state.bg].color

  style.define name, def

style_from_state = (state) ->
  name = { 'ansi' }
  append name, 'bold' if state.bold
  append name, 'italic' if state.italic
  append name, 'underline' if state.underline
  append name, state.fg if state.fg

  if state.bg
    append name, 'on'
    append name, state.bg

  name = table.concat name, '_'
  define_style name, state unless style[name]
  name

reset_style_state = (state) ->
  with state
    .italic = nil
    .bold = nil
    .underline = nil
    .fg = nil
    .bg = nil

style_state_has_any = (state) ->
  state.italic or state.bold or state.underline or state.fg or state.bg

apply_graphics_value = (val, state) ->
  n = tonumber val
  return unless n
  if n == 0
    reset_style_state state
  elseif n == 1
    state.bold = true
  elseif n == 3
    state.italic = true
  elseif n == 4
    state.underline = true
  elseif n == 22
    state.bold = nil
  elseif n >= 30 and n <= 37
    state.fg = ansi_colors[n - 29]
  elseif n == 39
    state.fg = nil
  elseif n >= 40 and n <= 47
    state.bg = ansi_colors[n - 39]
  elseif n == 49
    state.bg = nil

mark_style = (from_pos, style_state, styles) ->
  last = styles[#styles]
  if type(last) == 'string'
    styles[#styles + 1] = from_pos

  if style_state_has_any style_state
    styles[#styles + 1] = from_pos
    append styles, style_from_state style_state

parse_sequence = (p, p_idx, style_state) ->
  v = p[p_idx]
  return p_idx, nil unless v == left_bracket
  start_idx = p_idx
  p_idx += 1
  v = p[p_idx]

  while v != 0 and (v < 64 or v > 126)
    p_idx += 1
    v = p[p_idx]

  return p_idx + 1, nil if v != set_graphics_op -- unhandled, skip
  vals = ffi.string p + start_idx + 1, p_idx - start_idx - 1
  if #vals == 0
    reset_style_state style_state
  else
    for part in vals\gmatch '[^;]+'
      apply_graphics_value part, style_state

  p_idx + 1, style_state

delete_styles_back_to = (to_idx, styles) ->
  end_p = #styles
  last = styles[end_p]
  return if type(last) != 'number' or last < to_idx
  last = to_idx
  if styles[end_p - 2] >= last
    for i = end_p - 2, end_p
      styles[i] = nil
  else
    styles[end_p] = last

(text) ->
  buf = char_arr(#text)
  buf_idx = 0

  p = const_char_p(text)
  p_idx = 0
  styles = {}
  state = {}

  while p_idx < #text
    c = p[p_idx]

    if c == escape
      p_idx, new_style_state = parse_sequence p, p_idx + 1, state, styles
      if new_style_state
        state = new_style_state
        mark_style buf_idx + 1, state, styles

    elseif c == backspace and (buf_idx > 0)
      buf_idx -= 1
      while band(buf[buf_idx], 0xc0) == 0x80 -- back up continuation bytes
        buf_idx -= 1

      delete_styles_back_to buf_idx + 1, styles
      p_idx += 1

    else
      buf[buf_idx] = c
      buf_idx += 1
      p_idx += 1

  mark_style buf_idx + 1, {}, styles
  StyledText ffi.string(buf, buf_idx), styles
