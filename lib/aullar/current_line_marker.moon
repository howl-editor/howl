-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

flair = require 'aullar.flair'
{:max, :min} = math
{:define_class} = require 'aullar.util'
{:Attribute} = require 'ljglibs.pango'

flair.define 'current-line', {
  type: flair.RECTANGLE,
  background: '#8294ab'
  background_alpha: 0.2
  width: 'full'
}

flair.define 'current-line-overlay', {
  type: flair.SANDWICH,
  foreground: '#a3a3a3'
}

CurrentLineMarker = {
  new: (@view) =>

  draw_before: (x, y, display_line, cr, clip) =>
    flair.draw 'current-line', display_line, 1, 1, x, y, cr

  draw_after: (x, y, display_line, cr, clip) =>
    block = display_line.block
    overlay_flair = flair.get 'current-line-overlay'

    if block
      overlay_flair.width = block.width
      flair.draw overlay_flair, display_line, 1, 1, x, y, cr
    else
      overlay_flair.width = nil
      bg_ranges = display_line.background_ranges
      return unless #bg_ranges > 0

      for range in *bg_ranges
        flair.draw overlay_flair, display_line, range.start_offset, range.end_offset, x, y, cr
}

define_class CurrentLineMarker
