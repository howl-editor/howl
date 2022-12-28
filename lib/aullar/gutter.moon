-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:define_class} = require 'aullar.util'
Pango = require 'ljglibs.pango'
{:RGBA} = require 'ljglibs.gdk'
Layout = Pango.Layout
Gtk = require 'ljglibs.gtk'
pango_cairo = Pango.cairo

define_class {
  new: (@view, config) =>
    @number_chars = 0
    @width = 0
    @first_line = 0
    @last_line = 0
    @area = Gtk.DrawingArea {vexpand: true, css_classes: {'gutter'}}
    @area\set_draw_func self\_draw
    @reconfigure config
    @sync view

  properties: {
    visible: {
      get: => @area.visible
      set: (visible) => @area.visible = visible
    }
  }

  sync: =>
    return unless @area.visible
    view_first = @view.first_visible_line
    view_last = @view.last_visible_line
    if view_first != @first_line or view_last != @last_line
      @first_line = view_first
      @last_line = view_last
      @area\queue_draw!

  to_gobject: => @area

  reconfigure: (config) =>
    @foreground = RGBA(config.gutter_color)

  sync_dimensions: (buffer, opts = {}) =>
    return unless @area.visible
    lines_text = tostring(buffer.nr_lines)
    num_chars = #lines_text
    return if @number_chars == num_chars
    @_text_width = @view\text_dimensions(lines_text).width
    @width = @_text_width
    @area.content_width = @_text_width
    @number_chars = num_chars

  _draw: (cr, width, height) =>
    return if not @view.showing

    p_ctx = @area.pango_context
    d_lines = @view.display_lines

    view_first = @view.first_visible_line
    view_last = @view.last_visible_line

    c = @foreground
    cr\set_source_rgba c.red, c.green, c.blue, c.alpha

    layout = Layout p_ctx
    layout.width = @_text_width * Pango.SCALE
    layout.alignment = Pango.ALIGN_RIGHT

    y = 0

    for line_nr = view_first, view_last
      d_line = d_lines[line_nr]
      layout.text = tostring line_nr

      _, text_height = layout\get_pixel_size!
      line_height = d_line.height

      if d_line.is_wrapped
        layout_line = d_line.layout\get_line_readonly 0
        _, log_rect = layout_line\get_pixel_extents!
        line_height = log_rect.height

      cr\move_to 0, y + (line_height - text_height) / 2
      pango_cairo.show_layout cr, layout
      -- cr\restore!
      y += line_height



  start_draw: (@cairo_context, pango_context, @clip) =>
    @layout = nil
    -- return if @clip.x1 >= @width
    -- @_draw_background!
    -- @layout = Layout pango_context
    -- @layout.width = (@_text_width - 5) * Pango.SCALE
    -- @layout.alignment = Pango.ALIGN_RIGHT

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

    cr\move_to x + @background.padding_left, y + (line_height - text_height) / 2
    pango_cairo.show_layout cr, @layout
    cr\restore!

  end_draw: =>
    @cairo_context, @clip, @layout = nil, nil, nil

  _draw_background: =>
    @cairo_context\save!
    @background\draw @cairo_context
    @cairo_context\restore!
}
