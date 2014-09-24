-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Flair = require 'aullar.flair'
{:max, :min} = math
{:define_class} = require 'aullar.util'
{:Attribute} = require 'ljglibs.pango'

CurrentLineMarker = {
  new: (@view) =>
    @background_flair = Flair Flair.RECTANGLE, {
      background: '#8294ab'
      background_alpha: 0.2
      width: 'full'
    }

    @overlay_flair = Flair Flair.SANDWICH, {
      foreground: '#a3a3a3'
    }

  draw_before: (x, y, display_line, cr, clip) =>
    @background_flair\draw display_line, 1, 1, x, y, cr

  draw_after: (x, y, display_line, cr, clip) =>
    block = display_line.block
    if block
      @overlay_flair.opts.width = block.width
      @overlay_flair\draw display_line, 1, 1, x, y, cr
    else
      @overlay_flair.opts.width = nil
      bg_ranges = display_line.background_ranges
      return unless #bg_ranges > 0

      for range in *bg_ranges
        @overlay_flair\draw display_line, range.start_offset, range.end_offset, x, y, cr
}

define_class CurrentLineMarker
