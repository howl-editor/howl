-- Copyright 20222-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
{:define_class} = require 'aullar.util'
Pango = require 'ljglibs.pango'
{:RGBA} = require 'ljglibs.gdk'
Layout = Pango.Layout
Gtk = require 'ljglibs.gtk'
pango_cairo = Pango.cairo

ffi_cast = ffi.cast
int_t = ffi.typeof 'int'
cairo_t = ffi.typeof 'cairo_t *'

define_class {

  new: (@view, config) =>
    @number_chars = 0
    @first_line = 0
    @last_line = 0
    @area = Gtk.DrawingArea {vexpand: true, css_classes: {'gutter'}}
    @area\set_draw_func_for @, self._draw
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
    view_last = @view.last_visible_line + 1
    if view_first != @first_line or view_last != @last_line
      @first_line = view_first
      @last_line = view_last
      @area\queue_draw!

  to_gobject: => @area

  release: =>

  reconfigure: (config) =>
    @foreground = RGBA(config.gutter_color)

  sync_dimensions: (buffer, opts = {}) =>
    return unless @area.visible
    lines_text = tostring(buffer.nr_lines)
    num_chars = #lines_text
    return true if not opts.force and @number_chars == num_chars
    @_text_width = @view\text_dimensions(lines_text).width + 2
    @area.content_width = @_text_width
    @number_chars = num_chars

  _draw: (_, cr, width, height) =>
    cr = ffi_cast cairo_t, cr
    width = tonumber(ffi_cast int_t, width)
    height = tonumber(ffi_cast int_t, height)

    return if not @view.showing or not @area.visible

    p_ctx = @area.pango_context
    d_lines = @view.display_lines

    c = @foreground
    cr\set_source_rgba c.red, c.green, c.blue, c.alpha

    layout = Layout p_ctx
    layout.width = @_text_width * Pango.SCALE
    layout.alignment = Pango.ALIGN_RIGHT

    y = 0

    for line_nr = @first_line, @last_line
      d_line = d_lines[line_nr]
      break unless d_line
      layout.text = tostring line_nr

      _, text_height = layout\get_pixel_size!
      line_height = d_line.height
      total_height = line_height

      if d_line.is_wrapped
        layout_line = d_line.layout\get_line_readonly 0
        _, log_rect = layout_line\get_pixel_extents!
        line_height = log_rect.height

      cr\move_to 0, y + (line_height - text_height) / 2
      pango_cairo.show_layout cr, layout
      y += total_height
}
