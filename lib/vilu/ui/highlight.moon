import Scintilla from vilu
_G = _G
import error, pairs, append from _G
import string_to_color from Scintilla
bit = require 'bit'

highlights = {}
buffer_highlights = setmetatable {}, __mode: 'k'

_ENV = setmetatable {}, __index: highlights
setfenv 1, _ENV

-- Highlight styles
export PLAIN       = Scintilla.INDIC_PLAIN
export SQUIGGLE    = Scintilla.INDIC_SQUIGGLE
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
    \indic_set_fore num, string_to_color(def.color) if def.color

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

export apply = (name, buffer, pos, length) ->
  num = number_for name, buffer
  with buffer.sci
    \set_indicator_current number
    \indicator_fill_range pos - 1, length

export set_for_buffer = (sci, buffer) ->
  b_highlights = get_buffer_highlights buffer
  for name, num in pairs b_highlights
    highlight = highlights[name]
    set_highlight num, highlight, sci if highlight

export at_pos = (buffer, pos) ->
  on = buffer.sci\indicator_all_on_for pos - 1
  active = {}

  if on != 0
    b_highlights = get_buffer_highlights buffer
    for name, num in pairs b_highlights
      if highlights[name]
        append active, name if bit.band(on, num + 1) != 0

  active

return _ENV

