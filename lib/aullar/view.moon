-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
ffi_cast = ffi.cast

Gdk = require 'ljglibs.gdk'
Gtk = require 'ljglibs.gtk'
Pango = require 'ljglibs.pango'
Layout = Pango.Layout
require 'ljglibs.cairo.cairo'
pango_cairo = Pango.cairo
{:parse_key_event} = require 'ljglibs.util'
{:max, :min, :abs} = math

insertable_character = (event) ->
  return false if event.ctrl or event.alt or event.meta or event.super or not event.character
  true

on_key_press = (area, event, view) ->
  event = parse_key_event event

  if view.on_key_press
    handled = view.on_key_press view, event
    return if handled == true

  if insertable_character(event)
    view\insert event.character

draw_cursor = (base_y, column, cr, layout, height, view) ->
  cr\save!
  rect = layout\index_to_pos column
  cr\set_source_rgb 1, 0, 0
  base_x = math.max rect.x / 1024 - 1, 0
  cr\rectangle base_x, base_y + rect.y / 1024, view.cursor_width, rect.height / 1024
  cr\fill!
  cr\restore!

signals = {
  on_draw: (_, cr, view) -> view._draw view, cr
  on_screen_changed: (_, _, view) -> view._on_screen_changed view
  on_size_allocate: (_, allocation, view) ->
    view._on_size_allocate view, ffi_cast('GdkRectangle *', allocation)
}

View = {
  new: ->
    o = {
      _first_visible_line: 1
      cursor: 0
      cursor_width: 1.5
      line_spacing: 0.1
      _display_lines: {}

      area: Gtk.DrawingArea!
    }

    with o.area
      .can_focus = true
      \add_events Gdk.KEY_PRESS_MASK
      \on_key_press_event on_key_press, o
      \on_draw signals.on_draw, o
      \on_screen_changed signals.on_screen_changed, o
      \on_size_allocate signals.on_size_allocate, o

    o

  set_buffer: (buffer) =>
    @buffer = buffer

  move_cursor: (pos) =>
    old_line = @buffer\get_line_at_offset @cursor
    new_line = @buffer\get_line_at_offset pos

    @cursor = pos

    old_dl = @_display_lines[old_line.nr]
    new_dl = @_display_lines[new_line.nr]
    if old_dl and new_dl
      update_y = min(old_dl.y, new_dl.y)
      @area\queue_draw_area min(old_dl.x, new_dl.x),
        update_y,
        max(old_dl.width, new_dl.width),
        (max(old_dl.y, new_dl.y) - update_y) + max(old_dl.height, new_dl.height)
      else
        @area\queue_draw!

  insert: (text) =>
    @_invalidate_display_lines from: @cursor
    @buffer\insert @cursor, text
    @cursor += #text

  delete_back: =>
    return if @cursor == 0
    @buffer\delete @cursor - 1, 1 -- xxx
    @cursor -= 1 -- xxx
    @_invalidate_display_lines from: @cursor

  to_gobject: => @area

  _draw: (cr) =>
    p_ctx = @area.pango_context
    line_spacing = @line_spacing
    cursor = @cursor
    clip = cr.clip_extents

    cr\move_to 0, 0
    cr\set_source_rgb 0, 0, 0
    x, y = 0, 0

    for line in @buffer\lines @_first_visible_line
      d_line = @_display_lines[line.nr]

      unless d_line
        layout = Layout p_ctx
        layout\set_text line.text, line.size
        width, height = layout\get_pixel_size!
        d_line = { :x, :y, width: width + @cursor_width, :height, :line, :layout }
        @_display_lines[line.nr] = d_line

      break if d_line.y >= clip.y2

      if d_line.y >= clip.y1
        pango_cairo.show_layout cr, d_line.layout

        if cursor >= line.start_offset and cursor < line.end_offset
          draw_cursor y, cursor - line.start_offset, cr, d_line.layout, height, @

      y += d_line.height + (d_line.height * line_spacing)
      cr\move_to x, y

  _invalidate_display_lines: (what) =>
    d_lines = @_display_lines
    line = @_first_visible_line
    min_y, max_width = nil, 0

    while d_lines[line]
      d_line = d_lines[line]
      if d_line.line.end_offset >= what.from
        d_lines[line] = nil
        min_y or= d_line.y
        max_width = max(max_width, d_line.width)

      line += 1

    if min_y
      @area\queue_draw_area 0, min_y, max_width, @height - min_y

  _on_screen_changed: =>
    @_display_lines = {}

  _on_size_allocate: (allocation) =>
    @_display_lines = {}
    @width = allocation.width
    @height = allocation.height
}

-> setmetatable View.new!, __index: View
