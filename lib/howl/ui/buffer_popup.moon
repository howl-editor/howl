-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Gtk from lgi
import Scintilla from howl
import destructor from howl.aux
import Popup, style, highlight, theme from howl.ui

class BufferPopup extends Popup

  new: (buffer) =>
    error('Missing argument #1: buffer', 3) if not buffer
    @buffer = buffer
    @default_style = style.popup and style.popup.background and 'popup' or 'default'
    sci = @_create_sci buffer -- assignment to plain upvalue for the destructor to work
    @sci = sci
    @destructor = destructor -> buffer\remove_sci_ref sci

    @bin = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 3,
        left_padding: 3,
        right_padding: 3,
        bottom_padding: 3,
        @sci\to_gobject!
      }
    }

    super @bin, @_get_dimensions!
    theme.register_background_widget @bin, @default_style
    theme.register_background_widget @sci\to_gobject!, @default_style

  resize: =>
    dimensions = @_get_dimensions!
    super dimensions.width, dimensions.height

  keymap: {
    down: => @sci\line_scroll_down!
    up: => @sci\line_scroll_up!
    right: => @sci\line_scroll 1, 0
    left: => @sci\line_scroll -1, 0
    space: => @sci\page_down!
    backspace: => @sci\page_up!
    page_down: => @sci\page_down!
    page_up: => @sci\page_up!
  }

  _create_sci: (buffer) =>
    sci = Scintilla!

    with sci
      \set_doc_pointer buffer.doc
      \set_style_bits 8
      \set_code_page Scintilla.SC_CP_UTF8
      \set_hscroll_bar false
      \set_undo_collection false
      .listener =
        on_text_inserted: buffer\_on_text_inserted
        on_text_deleted: buffer\_on_text_deleted

    buffer\add_sci_ref sci
    style.register_sci sci, @default_style
    theme.register_sci sci
    style.set_for_buffer sci, buffer
    highlight.set_for_buffer sci, buffer
    sci

  _get_dimensions: =>
    char_width = @sci\text_width 32, ' '
    char_height = @sci\text_height 0
    height = (char_height * #@buffer.lines) + 6

    if @buffer.lines[#@buffer.lines].blank
      height -= char_height

    max_line = 0
    max_line = math.max(#line, max_line) for line in *@buffer.lines
    width = (max_line * char_width) + (char_width / 2) + 6
    return :width, :height

return BufferPopup
