-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:Attribute} = require 'ljglibs.pango'

ffi = require 'ffi'
C = ffi.C
{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Flair = require 'aullar.flair'

Selection = {
  new: (@view) =>
    @_anchor = nil
    @_end_pos = nil

    @background_flair = Flair(Flair.RECTANGLE, {
      background: '#a3d5da'
      background_alpha: 0.3
    })

    @overlay_flair = Flair(Flair.RECTANGLE, {
      background: '#c3e5ea'
      background_alpha: 0.4,
    })


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

    if start >= line.start_offset
      return start <= line.end_offset

    stop >= line.start_offset

  draw: (x, y, cr, display_line, line) =>
    start_x, width = x, display_line.width - @view.base_x
    start, stop = @range!
    start_col, end_col = 1, line.size + 1

    if start > line.start_offset -- sel starts on line
      start_col = (start - line.start_offset) + 1

    if stop < line.end_offset -- sel ends on line
      end_col = (stop - line.start_offset) + 1

    @background_flair\draw display_line, start_col, end_col, x, y, cr

  draw_overlay: (x, y, cr, display_line, line) =>
    bg_ranges = display_line.background_ranges
    return unless #bg_ranges > 0
    start, stop = @range!
    start_col = (start - line.start_offset) + 1
    end_col = (stop - line.start_offset) + 1

    for range in *bg_ranges
      break if range.start_offset > end_col
      if range.end_offset > start_col
        start_o = max start_col, range.start_offset
        end_o = min end_col, range.end_offset
        @overlay_flair\draw display_line, start_o, end_o, x, y, cr

}

define_class Selection
