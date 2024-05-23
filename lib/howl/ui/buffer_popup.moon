-- Copyright 2012-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

aullar = require 'aullar'
import View from aullar
import Popup, style from howl.ui
{:ceil} = math

keymap = {
  down: =>
    @view.first_visible_line += 1
    @view.cursor.line = @view.first_visible_line
  up: =>
    @view.first_visible_line -= 1
    @view.cursor.line = @view.first_visible_line
  right: => @view.base_x += @view.width_of_space
  left: => @view.base_x -= @view.width_of_space
  home: => @view.base_x = 0
  end: =>
    width = @view\block_dimensions @view.first_visible_line, @view.last_visible_line
    @view.base_x = width - @view.width
  space: => @view.cursor\page_down!
  backspace: => @view.cursor\page_up!
  page_down: => @view.cursor\page_down!
  page_up: => @view.cursor\page_up!
  escape: => @close!

  on_unhandled: ->
    -> true
}

class BufferPopup extends Popup

  new: (buffer, @opts = {}) =>
    error('Missing argument #1: buffer', 3) if not buffer
    @_buffer = buffer
    @default_style = style.popup and style.popup.background and 'popup' or 'default'
    @view = View buffer._buffer, focusable: false
    with @view.config
      .view_show_line_numbers = opts.show_line_numbers or false
      .view_show_cursor = false
      .view_show_h_scrollbar = false
      .view_show_v_scrollbar = false

    @view.listener = {
      on_resized: (view) ->
        for opt in *{'first_visible_line', 'middle_visible_line', 'last_visible_line'}
          if opts[opt]
            view[opt] = opts[opt]
    }

    @bin = @view\to_gobject!
    if opts.scrollable
      @keymap = keymap

    super @bin, @_get_dimensions!

  @property buffer:
    get: => @_buffer
    set: (b) =>
      @_buffer = b
      @view.buffer = b

  resize: =>
    dimensions = @_get_dimensions!
    super dimensions.width, dimensions.height

  _get_dimensions: =>
    first_line = @view.first_visible_line
    local nr_lines
    if @opts.show_lines
      nr_lines = math.min @opts.show_lines, #@_buffer.lines
    else
      nr_lines = #@_buffer.lines
      -- don't show the last line if empty
      if nr_lines > 1 and @_buffer.lines[nr_lines].is_blank
        nr_lines -= 1

    width, height = @view\block_dimensions first_line, first_line + nr_lines - 1
    margin = 3
    width += margin * 2
    height += margin * 2

    return width: ceil(width), height: ceil(height)

return BufferPopup
