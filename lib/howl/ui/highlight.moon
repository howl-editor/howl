-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

flair = require 'aullar.flair'

-- Highlight styles
export SANDWICH = flair.SANDWICH
export UNDERLINE = flair.UNDERLINE
export RECTANGLE = flair.RECTANGLE
export ROUNDED_RECTANGLE = flair.ROUNDED_RECTANGLE

setmetatable {
  SANDWICH: flair.SANDWICH
  UNDERLINE: flair.UNDERLINE
  RECTANGLE: flair.RECTANGLE
  ROUNDED_RECTANGLE: flair.ROUNDED_RECTANGLE

  define: (name, definition) ->
    flair.define name, definition

  define_default: (name, definition) ->
    flair.define_default name, definition

  apply: (name, buffer, pos, length) ->
    buffer.markers\add {
      name: 'highlight',
      flair: name,
      start_offset: pos,
      end_offset: pos + length
    }

  remove_all: (name, buffer) ->
    buffer.markers\remove name: 'highlight', flair: name

  remove_in_range: (name, buffer, start_pos, end_pos) ->
    buffer.markers\remove_for_range start_pos, end_pos, name: 'highlight', flair: name

  at_pos: (buffer, pos) ->
    [m.flair for m in *buffer.markers\at(pos, name: 'highlight')]

  set_for_theme: (theme) ->
    flair.define name, def for name, def in pairs(theme.highlights or {})

}, __index: (k) => flair.get(k)
