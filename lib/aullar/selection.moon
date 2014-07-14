-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C = ffi.C
{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'

Selection = {
  new: (@view) =>
    @_anchor = nil
    @_end_pos = nil

  properties: {
    is_empty: => @_anchor == nil

    anchor: {
      get: => @_anchor
      set: (anchor) => @_anchor = anchor
    }

    end_pos: {
      get: => @_end_pos
      set: (end_pos) => @_end_pos = end_pos
    }
  }

  set: (anchor, end_pos) =>
    @clear! unless @is_empty

    @_anchor = anchor
    @_end_pos = end_pos
    @view\refresh_display @range!

  extend: (from_pos, to_pos) =>
    if @is_empty
      @set from_pos, to_pos
    else
      @view\refresh_display min(to_pos, @_end_pos), max(to_pos, @_end_pos)
      @_end_pos = to_pos

  clear: =>
    return if @is_empty

    @view\refresh_display @range!
    @_anchor, @_end_pos = nil, nil

  range: =>
    min(@_anchor, @_end_pos), max(@_anchor, @_end_pos)

  affects_line: (line) =>
    return false if @is_empty
    start, stop = @range!

    if (start - 1) >= line.start_offset
      return (start - 1) <= line.end_offset

    stop - 1 >= line.start_offset

  draw: (base_x, base_y, cr, display_line, line) =>
    x, width = base_x, display_line.width
    start, stop = @range!

    if (start - 1) > line.start_offset -- sel starts on line
      start_col = (start - 1) - line.start_offset
      rect = display_line.layout\index_to_pos start_col
      x = base_x + (rect.x / 1024)
      width -= (x - base_x)

    if (stop - 1) < line.end_offset -- sel ends on line
      end_col = (stop - 1) - line.start_offset
      rect = display_line.layout\index_to_pos end_col
      width = (base_x + rect.x / 1024) - x

    cr\save!
    cr\set_source_rgb 0.6, 0.8, 0.8
    cr\rectangle x, base_y, width, display_line.height + 1
    cr\fill!
    -- print "fill_extents"
    -- moon.p cr.fill_extents
    -- cr\stroke!
    cr\restore!
}

define_class Selection
