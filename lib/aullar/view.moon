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
Cursor = require 'aullar.cursor'
Selection = require 'aullar.selection'
Buffer = require 'aullar.buffer'
LineGutter = require 'aullar.line_gutter'
{:define_class} = require 'aullar.util'
{:parse_key_event} = require 'ljglibs.util'
{:max, :min, :abs} = math

insertable_character = (event) ->
  return false if event.ctrl or event.alt or event.meta or event.super or not event.character
  true

contains_newlines = (s) ->
  s\find('[\n\r]') != nil

on_key_press = (area, event, view) ->
  event = parse_key_event event

  if view.on_key_press
    handled = view.on_key_press view, event
    return if handled == true

  if insertable_character(event)
    view\insert event.character

draw_current_line_background = (x, y, display_line, cr, clip) ->
  cr\save!
  cr\set_source_rgb 0.85, 0.85, 0.85
  cr\rectangle x, y, clip.x2 - x, display_line.height + 1
  cr\fill!
  cr\restore!

signals = {
  on_draw: (_, cr, view) -> view._draw view, cr
  on_focus_in: (_, _, view) -> view._on_focus_in view
  on_focus_out: (_, _, view) -> view._on_focus_out view
  on_screen_changed: (_, _, view) -> view._on_screen_changed view
  on_size_allocate: (_, allocation, view) ->
    view._on_size_allocate view, ffi_cast('GdkRectangle *', allocation)
}

View = {
  new: (@_buffer = Buffer('')) =>
    @line_spacing = 0.1
    @margin = 3

    @_first_visible_line = 1
    @_last_visible_line = 1
    @area = Gtk.DrawingArea!
    @selection = Selection @
    @cursor = Cursor @, @selection

    with @area
      .can_focus = true
      \add_events Gdk.KEY_PRESS_MASK
      \on_key_press_event on_key_press, @
      \on_draw signals.on_draw, @
      \on_screen_changed signals.on_screen_changed, @
      \on_size_allocate signals.on_size_allocate, @
      \on_focus_in_event signals.on_focus_in, @
      \on_focus_out_event signals.on_focus_out, @

    @_reset_display!

  properties: {

    first_visible_line: {
      get: => @_first_visible_line
      set: (line) =>
        if line != @_first_visible_line
          @_first_visible_line = line
          @_last_visible_line = line
          @area\queue_draw!
    }

    last_visible_line: {
      get: => @_last_visible_line
      set: (line) =>
        -- todo: variable height lines
        @first_visible_line = (line - @lines_showing) + 1
        @_last_visible_line = line
    }

    lines_showing: => @last_visible_line - @first_visible_line + 1

    buffer: {
      get: => @_buffer
      set: (buffer) =>
        @_buffer = buffer
    }
  }

  insert: (text) =>
    cur_pos = @cursor.pos
    @_buffer\insert cur_pos - 1, text

    if contains_newlines(text)
      @refresh_display cur_pos - 1, nil, invalidate: true
    else
      @refresh_display cur_pos - 1, cur_pos + #text - 1, invalidate: true

    @cursor.pos += #text

  delete_back: =>
    cur_line = @cursor.line
    cur_pos = @cursor.pos
    @cursor\backward!
    @_buffer\delete @cursor.pos - 1, cur_pos - @cursor.pos

    if cur_line != @cursor.line -- lines changed, everything after is invalid
      @refresh_display @cursor.pos - 1, nil, invalidate: true
    else -- within the current line
      @refresh_display @cursor.pos - 1, cur_pos - 1, invalidate: true

  to_gobject: => @area

  _draw: (cr) =>
    p_ctx = @area.pango_context
    line_spacing = @line_spacing
    cursor_pos = @cursor.pos - 1
    clip = cr.clip_extents
    line_gutter = LineGutter @, cr, p_ctx, clip

    x, y = line_gutter.width + @margin, @margin
    cr\move_to x, y
    cr\set_source_rgb 0, 0, 0
    last_visible_line = 0

    for line in @_buffer\lines @_first_visible_line
      d_line = @display_lines[line.nr]
      break if y >= clip.y2

      if y >= clip.y1
        is_current_line = @cursor\in_line line

        if is_current_line
          draw_current_line_background x, y, d_line, cr, clip

        if @selection\affects_line line
          @selection\draw x, y, cr, d_line, line

        cr\move_to x + (d_line.spacing / 2), y
        pango_cairo.show_layout cr, d_line.layout
        line_gutter\draw_for_line line.nr, 0, y, d_line

        if is_current_line
          @cursor\draw x, y, cursor_pos - line.start_offset, cr, d_line

      if y + d_line.text_height < clip.y2
        last_visible_line = line.nr

      y += d_line.height + 1
      cr\move_to x, y

    @_last_visible_line = max(@_last_visible_line or 0, last_visible_line)

  refresh_display: (from_offset, to_offset, opts = {}) =>
    return unless @_last_visible_line and @width
    d_lines = @display_lines
    min_y, max_y = nil, nil
    x, y = 0, @margin
    last_valid = 0

    for line_nr = @_first_visible_line, @_last_visible_line
      d_line = d_lines[line_nr]
      line = @_buffer\get_line line_nr
      after = to_offset and line.start_offset > to_offset
      break if after
      before = line.end_offset < from_offset

      if not(before or after) or (after and not to_offset)
        d_lines[line.nr] = nil if opts.invalidate
        min_y or= y
        max_y = y + d_line.height
      else
        last_valid = max last_valid, line.nr

      y += d_line.height + 1

    if opts.invalidate and not to_offset
      max_y = @height
      for line_nr = last_valid + 1, @_max_display_line
        d_lines[line_nr] = nil

      @_max_display_line = last_valid

    if min_y
      @area\queue_draw_area 0, min_y, @width, (max_y - min_y) + 1

  _reset_display: =>
    @_max_display_line = 0
    v = @
    @display_lines = setmetatable {}, {
      __index: (t, nr) ->
        line = v.buffer\get_line nr
        layout = Layout v.area.pango_context
        layout\set_text line.text, line.size
        width, text_height = layout\get_pixel_size!
        spacing = math.ceil (text_height * v.line_spacing) - 0.5

        d_line = {
          width: width + v.cursor.width,
          height: text_height + spacing,
          :text_height,
          :layout,
          :spacing
        }
        v._max_display_line = max v._max_display_line, nr
        rawset t, nr, d_line
        d_line
    }

  _on_focus_in: =>
    @cursor.active = true

  _on_focus_out: =>
    @cursor.active = false

  _on_screen_changed: =>
    @_reset_display!

  _on_size_allocate: (allocation) =>
    @_reset_display!
    @width = allocation.width
    @height = allocation.height

}

define_class View
