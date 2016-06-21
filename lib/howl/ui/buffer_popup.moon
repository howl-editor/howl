-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

aullar = require 'aullar'
import View from aullar
import Popup, style from howl.ui
{:ceil, :max} = math

class BufferPopup extends Popup

  new: (buffer) =>
    error('Missing argument #1: buffer', 3) if not buffer
    @buffer = buffer
    @default_style = style.popup and style.popup.background and 'popup' or 'default'
    @view = View buffer._buffer
    with @view.config
      .view_show_line_numbers = false
      .view_show_cursor = false

    @bin = @view\to_gobject!

    super @bin, @_get_dimensions!

  resize: =>
    dimensions = @_get_dimensions!
    super dimensions.width, dimensions.height

  keymap: {
    down: => @view.cursor\down!
    up: => @view.cursor\up!
    -- right: => @sci\line_scroll 1, 0
    -- left: => @sci\line_scroll -1, 0
    space: => @view.cursor\page_down!
    -- backspace: => @sci\page_up!
    page_down: => @view.cursor\page_down!
    page_up: => @view.cursor\page_up!
  }

  _get_dimensions: =>
    nr_lines = #@buffer.lines
    if nr_lines > 1 and @buffer.lines[nr_lines].is_blank
      nr_lines -= 1

    width, height = @view\block_dimensions 1, nr_lines
    margin = max @view.margin, 3
    width += margin * 2
    height += margin * 2

    return width: ceil(width), height: ceil(height)

return BufferPopup
