-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Pango = require 'ljglibs.pango'
{:RGBA} = require 'ljglibs.gdk'
Layout = Pango.Layout
pango_cairo = Pango.cairo

CLayout = require 'ljglibs.pango.layout'

LineGutter = {
  new: (@view) =>
    @width = 50

  start_draw: (@cairo_context, pango_context, @clip) =>
    @layout = nil
    return if @clip.x1 >= @width
    @_draw_background!
    @layout = Layout pango_context
    @layout.width = (@width - 5) * 1024
    @layout.alignment = Pango.ALIGN_RIGHT

  draw_for_line: (line_nr, x, y, display_line) =>
    return unless @layout

    cr = @cairo_context
    cr\save!
    @layout.text = tostring line_nr
    _, text_height = @layout\get_pixel_size!
    cr\move_to x, y + (display_line.height - text_height) / 2
    pango_cairo.show_layout cr, @layout
    cr\restore!

  end_draw: =>
    @cairo_context, @clip, @layout = nil, nil, nil

  _draw_background: =>
    with @cairo_context
      \save!
      color = RGBA('#8294ab')
      \set_source_rgba color.red, color.green, color.blue, 0.3
      \rectangle @clip.x1, @clip.y1, min(@clip.x2 - @clip.x1, @width), @clip.y2 - @clip.y1
      \fill!
      \restore!
}

define_class LineGutter
