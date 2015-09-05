-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
aullar = require 'aullar'
import View from aullar
import destructor from howl.aux
import Popup, style, highlight, theme from howl.ui

class BufferPopup extends Popup

  new: (buffer) =>
    error('Missing argument #1: buffer', 3) if not buffer
    @buffer = buffer
    @default_style = style.popup and style.popup.background and 'popup' or 'default'
    @view = View buffer._buffer
    with @view.config
      .view_show_line_numbers = false
      .view_show_cursor = false
    @buffer\lex!

    @bin = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 3,
        left_padding: 3,
        right_padding: 3,
        bottom_padding: 3,
        @view\to_gobject!
      }
    }

    super @bin, @_get_dimensions!

    theme.register_background_widget @bin, @default_style
    theme.register_background_widget @view\to_gobject!, @default_style

  resize: =>
    dimensions = @_get_dimensions!
    super dimensions.width, dimensions.height

  keymap: {
    down: => @view.cursor\down!
    up: => @view.cursor\up!
    -- right: => @sci\line_scroll 1, 0
    -- left: => @sci\line_scroll -1, 0
    space: => @view.cursor\page_down!
    backspace: => @sci\page_up!
    page_down: => @view.cursor\page_down!
    page_up: => @view.cursor\page_up!
  }

  _get_dimensions: =>
    dimensions = @view\text_dimensions 'M'
    margin = @view.margin * 2
    height = (dimensions.height * #@buffer.lines) + 6 + margin

    if @buffer.lines[#@buffer.lines].is_blank
      height -= dimensions.height

    max_line = 0
    max_line = math.max(#line, max_line) for line in *@buffer.lines
    width = (max_line * dimensions.width) + (dimensions.width / 2) + 6
    return :width, :height

return BufferPopup
