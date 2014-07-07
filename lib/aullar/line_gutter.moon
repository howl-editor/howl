-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Pango = require 'ljglibs.pango'
Layout = Pango.Layout
pango_cairo = Pango.cairo

CLayout = require 'ljglibs.pango.layout'

LineGutter = {
  new: (@view, @cairo_context, @pango_context, @clip) =>
    @width = 50
    @_draw_background!
    @layout = Layout @pango_context
    @layout.width = (@width - 5) * 1024
    @layout.alignment = Pango.ALIGN_RIGHT

  properties: {
  }

  draw_for_line: (line_nr, x, y, display_line) =>
    cr = @cairo_context
    cr\move_to x, y
    @layout.text = tostring line_nr
    pango_cairo.show_layout cr, @layout
    cr\save!
    cr\restore!

  _draw_background: =>
    cr = @cairo_context

    cr\save!
    cr\set_source_rgb 0.5, 0.6, 0.4
    cr\rectangle @clip.x1, @clip.y1, min(@clip.x2, @width), @clip.y2
    cr\fill!
    cr\restore!
}

define_class LineGutter
