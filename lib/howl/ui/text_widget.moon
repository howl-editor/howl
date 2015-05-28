-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
aullar = require 'aullar'
import config from howl
import View from aullar
import PropertyObject from howl.aux.moon
import theme, Cursor, Selection, ActionBuffer from howl.ui

class TextWidget extends PropertyObject
  new: (@opts={}) =>
    super!

    @buffer = ActionBuffer!
    @buffer.title = 'TextWidget'
    @view = View @buffer._buffer
    @view.margin = 0
    with @view.config
      .view_show_inactive_cursor = false
      .view_line_padding = config.line_padding

    @cursor = Cursor self, Selection @view
    @view_gobject = @view\to_gobject!
    @view_gobject\on_map self\_on_map

    padding_box = Gtk.Alignment {
      top_padding: @opts.top_padding or 3,
      left_padding: @opts.left_padding or 3,
      right_padding: @opts.right_padding or 1,
      bottom_padding: @opts.bottom_padding or 1,
      @view_gobject
    }
    container = Gtk.EventBox {
      padding_box
    }
    container.style_context\add_class 'aullar_container'

    top_border = @opts.top_border or 1
    bottom_border = @opts.bottom_border or 0
    container_box = Gtk.Box Gtk.ORIENTATION_VERTICAL

    if top_border > 0
      divider = Gtk.EventBox height_request: top_border
      divider.style_context\add_class 'divider'
      container_box\pack_start divider, false, 0, 0

    if bottom_border > 0
      divider = Gtk.EventBox height_request: bottom_border
      divider.style_context\add_class 'divider'
      container_box\pack_end divider, false, 0, 0

    container_box\add container

    @box = Gtk.EventBox {
      hexpand: true,
      container_box
    }
    @box.style_context\add_class 'aullar_box'

    @_top_gap = padding_box.top_padding + top_border
    @_bottom_gap = padding_box.bottom_padding + bottom_border
    @_left_gap = padding_box.left_padding
    @_right_gap = padding_box.right_padding

    theme.register_background_widget @view_gobject, opts.default_style

    @height_rows = 1

    @view.listener =
      on_key_press: (_, ...) ->
        @opts.on_keypress and @opts.on_keypress ...

      on_insert_at_cursor: (...) ->
        @opts.on_text_inserted and @opts.on_text_inserted ...
        @opts.on_changed and @opts.on_changed!

      on_delete_back: (...) ->
        @opts.on_changed and @opts.on_changed!

      on_focus_out: @opts.on_focus_lost

  @property width_cols:
    get: =>
      dimensions = @view\text_dimensions 'M'
      return math.floor @view_gobject.allocated_width / dimensions.width

  @property height:
    get: => @_height
    set: (val) =>
      -- round to multiple of row-height
      @height_rows = math.floor val / @row_height

  @property padded_height: get: => @height + @_top_gap + @_bottom_gap

  @property height_rows:
    get: => @_height_rows
    set: (rows) =>
      @_height_rows = rows
      @_set_height rows * @row_height

  @property width:
    get: => @_width or @view_gobject.allocated_width
    set: (val) => @_set_width val

  @property padded_width: get: => @width + @_left_gap + @_right_gap

  @property row_height:
    get: => @view\text_dimensions('M').height

  _set_height: (height) =>
    return if @_height == height
    @_height = height
    @view_gobject.height_request = height

  _set_width: (width) =>
    @_width = width
    @view_gobject.width_request = height

  adjust_width_to_fit: =>
    char_width = @view\text_dimensions('M').width
    max_line = 0
    max_line = math.max(#line, max_line) for line in *@buffer.lines
    @width = (max_line * char_width) + (char_width / 2)

  to_gobject: => @box

  @property text:
    get: => @buffer.text
    set: (text) => @buffer.text = text

  @property is_focus:
    get: => @view.has_focus

  focus: => @view\grab_focus!

  delete_back: => @view\delete_back!

  show: =>
    @text = @opts.text if @opts.text
    @showing = true
    @to_gobject!\show_all!

  hide: =>
    @to_gobject!\hide!
    @showing = false

  append: (...) => @buffer\append ...

  insert: (...) => @buffer\insert ...

  delete: (...) => @buffer\delete ...

  _on_map: (...) =>
    @height_rows = @height_rows if @height_rows
    if @width_cols > 0
      @opts.on_map and @opts.on_map!
