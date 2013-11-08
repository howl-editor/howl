-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Scintilla from howl
import print, tostring, error, pairs, append from _G
bit = require 'bit'

highlights = {}
buffer_highlights = setmetatable {}, __mode: 'k'

_ENV = setmetatable {}, __index: highlights
setfenv 1, _ENV

-- Highlight styles
export PLAIN       = Scintilla.INDIC_PLAIN
export SQUIGGLE    = Scintilla.INDIC_SQUIGGLEPIXMAP
export TT          = Scintilla.INDIC_TT
export DIAGONAL    = Scintilla.INDIC_DIAGONAL
export STRIKE      = Scintilla.INDIC_STRIKE
export HIDDEN      = Scintilla.INDIC_HIDDEN
export BOX         = Scintilla.INDIC_BOX
export ROUNDBOX    = Scintilla.INDIC_ROUNDBOX
export STRAIGHTBOX = Scintilla.INDIC_STRAIGHTBOX
export DASH        = Scintilla.INDIC_DASH
export DOTS        = Scintilla.INDIC_DOTS
export SQUIGGLELOW = Scintilla.INDIC_SQUIGGLELOW
export DOTBOX      = Scintilla.INDIC_DOTBOX

get_buffer_highlights = (buffer) ->
  buffer_highlights[buffer] = _next_number: 0 if not buffer_highlights[buffer]
  buffer_highlights[buffer]

set_highlight = (num, def, sci) ->
  with sci
    \indic_set_style num, def.style if def.style
    \indic_set_alpha num, def.alpha if def.alpha
    \indic_set_outline_alpha num, def.outline_alpha if def.outline_alpha
    \indic_set_under num, def.under if def.under
    \indic_set_fore num, def.color if def.color

export number_for = (name, buffer) ->
  b_highlights = get_buffer_highlights buffer
  num = b_highlights[name]

  return num if num

  def = highlights[name]
  if not def then error 'Could not find highlight "' .. name .. '"', 2

  num = b_highlights._next_number
  if num > Scintilla.INDIC_MAX
    error('Maximum number of highlights exceeded (' .. Scintilla.INDIC_MAX .. ')')

  b_highlights[name] = num
  b_highlights._next_number += 1

  set_highlight num, def, sci for sci in *buffer.scis

  return num

export define = (name, definition) ->
  highlights[name] = definition

  for buffer, hls in pairs buffer_highlights
    if hls[name]
      set_highlight hls[name], definition, sci for sci in *buffer.scis

export define_default = (name, definition) ->
  return if highlights[name]
  define name, definition

export apply = (name, buffer, pos, length) ->
  num = number_for name, buffer
  end_pos = pos + length
  pos, end_pos = buffer\byte_offset pos, end_pos
  with buffer.sci
    \set_indicator_current num
    \indicator_fill_range pos - 1, end_pos - pos

export set_for_buffer = (sci, buffer) ->
  b_highlights = get_buffer_highlights buffer
  for name, num in pairs b_highlights
    highlight = highlights[name]
    set_highlight num, highlight, sci if highlight

export at_pos = (buffer, pos) ->
  b_pos = buffer\byte_offset pos
  on = buffer.sci\indicator_all_on_for b_pos - 1
  active = {}

  if on != 0
    b_highlights = get_buffer_highlights buffer
    for name, num in pairs b_highlights
      if highlights[name]
        append active, name if bit.band(on, num + 1) != 0

  active

export remove_all = (name, buffer) ->
  num = number_for name, buffer
  with buffer.sci
    \set_indicator_current num
    \indicator_clear_range 0, buffer.size

export remove_in_range = (name, buffer, start_pos, end_pos) ->
  start_pos, end_pos = buffer\byte_offset start_pos, end_pos
  num = number_for name, buffer
  sci = buffer.sci
  sci\set_indicator_current num
  loop = 0
  while start_pos < end_pos
    loop += 1
    break if loop > 3
    start_pos = sci\indicator_start num, start_pos
    break if start_pos < 0
    end_pos = sci\indicator_end num, start_pos
    break if start_pos == end_pos
    sci\indicator_clear_range start_pos, end_pos - start_pos
    start_pos = end_pos + 1

export set_for_theme = (theme) ->
  define name, def for name, def in pairs(theme.highlights or {})

return _ENV
