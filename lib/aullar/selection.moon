-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:Attribute} = require 'ljglibs.pango'

ffi = require 'ffi'
C = ffi.C
{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
flair = require 'aullar.flair'

flair.define 'selection', {
  type: flair.RECTANGLE,
  background: '#a3d5da',
  background_alpha: 0.6,
  min_width: 'letter'
}

flair.define 'selection-overlay', {
  type: flair.RECTANGLE,
  background: '#c3e5ea',
  background_alpha: 0.4,
  min_width: 'letter'
}

Selection = {
  new: (@view) =>
    @_anchor = nil
    @_end_pos = nil

  properties: {
    is_empty: => (@_anchor == nil) or (@_anchor == @_end_pos)

    size: =>
      return 0 if @is_empty
      abs @_anchor - @_end_pos

    anchor: {
      get: => @_anchor
      set: (anchor) =>
        return if anchor == @_anchor

        error "Can't set anchor when selection is empty", 2 if @is_empty
        @_anchor = anchor
        @view\refresh_display @range!
        @_notify_change!
    }

    end_pos: {
      get: => @_end_pos
      set: (end_pos) =>
        return if end_pos == @_end_pos

        error "Can't set end_pos when selection is empty", 2 if @is_empty
        @_end_pos = end_pos
        @view\refresh_display @range!
        @_notify_change!
    }
  }

  set: (anchor, end_pos) =>
    return if anchor == @_anchor and end_pos == @_end_pos

    @clear! unless @is_empty

    @_anchor = anchor
    @_end_pos = end_pos
    @view\refresh_display @range!
    @_notify_change!

  extend: (from_pos, to_pos) =>
    if @is_empty
      @set from_pos, to_pos
    else
      @view\refresh_display min(to_pos, @_end_pos), max(to_pos, @_end_pos)
      @_end_pos = to_pos
      @_notify_change!

  clear: =>
    return unless @_anchor and @_end_pos

    @view\refresh_display @range!
    @_anchor, @_end_pos = nil, nil
    @_notify_change!

  range: =>
    return nil, nil if @is_empty
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
    sel_start, sel_end = false, false

    if start > line.start_offset -- sel starts on line
      start_col = (start - line.start_offset) + 1
      sel_start = true

    if stop <= line.end_offset -- sel ends on line
      end_col = (stop - line.start_offset) + 1
      sel_end = true

    return if start_col == end_col and (sel_start or sel_end)
    flair.draw 'selection', display_line, start_col, end_col, x, y, cr

  draw_overlay: (x, y, cr, display_line, line) =>
    bg_ranges = display_line.background_ranges
    return unless #bg_ranges > 0
    start, stop = @range!
    start_col = (start - line.start_offset) + 1
    end_col = (stop - line.start_offset) + 1
    sel_start = start > line.start_offset
    sel_end = stop <= line.end_offset

    for range in *bg_ranges
      break if range.start_offset > end_col
      if range.end_offset > start_col
        start_o = max start_col, range.start_offset
        end_o = min end_col, range.end_offset
        continue if start_o == end_o and (sel_start or sel_end)
        flair.draw 'selection-overlay', display_line, start_o, end_o, x, y, cr

  _notify_change: =>
    if @listener and @listener.on_selection_changed
      @listener.on_selection_changed @listener, self
}

define_class Selection
