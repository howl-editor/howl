-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Pango = require 'ljglibs.pango'
{:RGBA} = require 'ljglibs.gdk'
Layout = Pango.Layout
pango_cairo = Pango.cairo

define_class {
  new: (@view) =>
    @number_chars = 0
    @width = 0

  sync_width: (buffer, opts = {}) =>
    lines_text = tostring(buffer.nr_lines)
    num_chars = #lines_text
    return true if not opts.force and @number_chars == num_chars
    {:width} = @view\text_dimensions(lines_text)
    @width = width + 10
    @number_chars = num_chars
    false

  start_draw: (@cairo_context, pango_context, @clip, styling) =>
    @layout = nil
    return if @clip.x1 >= @width
    @_draw_background styling
    @layout = Layout pango_context
    @layout.width = (@width - 5) * Pango.SCALE
    @layout.alignment = Pango.ALIGN_RIGHT
    @_foreground = RGBA(styling.foreground or '#000000')
    @_foreground_alpha = styling.foreground_alpha or 1

  draw_for_line: (line_nr, x, y, display_line) =>
    return unless @layout

    cr = @cairo_context
    color = @_foreground
    cr\save!
    cr\set_source_rgba color.red, color.green, color.blue, @_foreground_alpha
    @layout.text = tostring line_nr
    _, text_height = @layout\get_pixel_size!
    line_height = display_line.height

    if display_line.is_wrapped
      layout_line = display_line.layout\get_line_readonly 0
      _, log_rect = layout_line\get_pixel_extents!
      line_height = log_rect.height

    cr\move_to x, y + (line_height - text_height) / 2
    pango_cairo.show_layout cr, @layout
    cr\restore!

  end_draw: =>
    @cairo_context, @clip, @layout = nil, nil, nil

  _draw_background: (styling) =>
    with @cairo_context
      \save!
      color = RGBA(styling.background or '#8294ab')
      alpha = styling.background_alpha or 1
      \set_source_rgba color.red, color.green, color.blue, alpha
      \rectangle @clip.x1, @clip.y1, min(@clip.x2 - @clip.x1, @width), @clip.y2 - @clip.y1
      \fill!
      \restore!
}
