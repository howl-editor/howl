-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

aullar = require 'aullar'
import config from howl
import View from aullar
import PropertyObject from howl.util.moon
import Cursor, Selection, ActionBuffer from howl.ui
{:max} = math

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
      .view_show_h_scrollbar = false
      .view_line_wrap = @opts.line_wrap

    @selection = Selection @view
    @cursor = Cursor self, @selection
    @view_gobject = @view\to_gobject!

    @visible_rows = 1

    @view.listener =
      on_key_press: (_, ...) ->
        @opts.on_keypress and @opts.on_keypress ...

      on_insert_at_cursor: (...) ->
        @opts.on_text_inserted and @opts.on_text_inserted ...
        @opts.on_changed and @opts.on_changed!

      on_delete_back: (...) ->
        @opts.on_changed and @opts.on_changed!

      on_focus_out: @opts.on_focus_lost
      on_resized: @opts.on_resized

  @property width_cols:
    get: =>
      dimensions = @view\text_dimensions 'M'
      return math.floor @view_gobject.allocated_width / dimensions.width

  @property height:
    get: => @_height
    set: (val) => error "Don't set height, set `visible_rows`"

  @property visible_rows:
    get: => @_visible_rows
    set: (nr) =>
      @_visible_rows = nr
      @adjust_height!

  @property width:
    get: => @_width or @view_gobject.allocated_width
    set: (val) => @_set_width val

  @property text:
    get: => @buffer.text
    set: (text) => @buffer.text = text

  @property can_focus:
    get: => @view_gobject.can_focus
    set: (v) => @view_gobject.can_focus = v

  adjust_width_to_fit: =>
    width = @view\block_dimensions 1, @visible_rows
    default_char_width = @view\text_dimensions('M').width
    @_set_width max(width, default_char_width * 10) + (default_char_width / 2)

  adjust_height: =>
    default_row_height = @view\text_dimensions('M').height
    _, height = @view\block_dimensions 1, @visible_rows
    @_set_height max(height, default_row_height)

  to_gobject: => @view_gobject

  focus: => @view\grab_focus!

  delete_back: => @view\delete_back!

  show: =>
    @text = @opts.text if @opts.text
    @showing = true
    @adjust_height!
    @to_gobject!\show!

  hide: =>
    @to_gobject!\hide!
    @showing = false

  append: (...) => @buffer\append ...

  insert: (...) => @buffer\insert ...

  delete: (...) => @buffer\delete ...

  _set_height: (height) =>
    return if @_height == height
    @_height = height
    @view_gobject.height_request = height

  _set_width: (width) =>
    return if @_width == width
    @_width = width
    @view_gobject.width_request = width
