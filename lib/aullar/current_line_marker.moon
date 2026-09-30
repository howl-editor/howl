-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

flair = require 'aullar.flair'
{:define_class} = require 'aullar.util'

flair.define 'current_line', {
  type: flair.RECTANGLE,
  background: '#8294ab',
  background_alpha: 0.2,
}

flair.define 'current_line_overlay', {
  type: flair.SANDWICH,
  foreground: '#a3a3a3'
}

CurrentLineMarker = {
  new: (@view) =>

  draw_before: (x, y, display_line, cr, col) =>
    @_offset = 1
    @_height = display_line.height
    current_flair = flair.get 'current_line'

    if display_line.is_wrapped
      if @view.config.view_line_wrap_navigation == 'visual'
        @_offset = display_line.lines\at(col).line_start
        @_height = nil -- defaults to visual line

    -- spans the view whatever the definition says, so themes needn't set a width
    current_flair.width = 'full'
    current_flair.height = @_height
    flair.draw current_flair, display_line, @_offset, @_offset, x, y, cr

  draw_after: (x, y, display_line, cr, col) =>
    block = display_line.block
    overlay_flair = flair.get 'current_line_overlay'

    if block
      overlay_flair.width = block.width
      overlay_flair.height = @_height
      flair.draw overlay_flair, display_line, @_offset, @_offset, x, y, cr
    else
      overlay_flair.width = nil
      overlay_flair.height = nil
      bg_ranges = display_line.background_ranges
      return unless #bg_ranges > 0

      for range in *bg_ranges
        flair.draw overlay_flair, display_line, range.start_offset, range.end_offset, x, y, cr
}

define_class CurrentLineMarker
