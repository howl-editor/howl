-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
import Scintilla, bindings, log from howl
import PropertyObject from howl.aux.moon
import highlight, style, theme, Cursor, Selection, ActionBuffer, IndicatorBar from howl.ui

class TextWidget extends PropertyObject
  new: (@opts={}) =>
    super!
    @_init_sci!

  _init_sci: =>
    @sci = Scintilla!
    with @sci
      \set_style_bits 8
      \set_wrap_mode  @opts.line_wrapping == 'char' and Scintilla.SC_WRAP_CHAR or Scintilla.SC_WRAP_NONE
      \set_lexer Scintilla.SCLEX_NULL
      \clear_all_cmd_keys!
      \set_hscroll_bar false
      \set_undo_collection false

    @selection = Selection @sci
    @cursor = Cursor self, @selection

    @buffer = ActionBuffer @sci
    @buffer.text = ''
    @buffer.title = 'TextWidget'


    @gsci = @sci\to_gobject!
    @gsci\on_map -> @_on_map!

    style.register_sci @sci, @opts.default_style
    theme.register_sci @sci
    style.set_for_buffer @sci, @buffer
    highlight.set_for_buffer @sci, @buffer

    padding_box = Gtk.Alignment {
      top_padding: @opts.top_padding or 3,
      left_padding: @opts.left_padding or 3,
      right_padding: @opts.right_padding or 1,
      bottom_padding: @opts.bottom_padding or 1,
      @gsci
    }

    sci_container = Gtk.EventBox {
      padding_box
    }

    sci_container\on_realize ->
      theme.register_background_widget sci_container, @opts.default_style
    sci_container\on_unrealize ->
      theme.unregister_background_widget sci_container

    border_box = Gtk.Alignment {
      top_padding: @opts.top_border or 1,
      bottom_padding: @opts.bottom_border or 0,
      sci_container
    }

    @box = Gtk.EventBox {
      hexpand: true
      border_box
    }
    @box.style_context\add_class 'sci_box'

    @_set_appearance!

    @sci.listener =
      on_keypress: @opts.on_keypress
      on_text_inserted: (...) ->
        @buffer\_on_text_inserted ...
        @opts.on_text_inserted and @opts.on_text_inserted ...
      on_text_deleted: (...) ->
        @buffer\_on_text_deleted ...
        @opts.on_text_deleted and @opts.on_text_deleted ...
      on_changed: @opts.on_changed
      on_focus_lost: @opts.on_focus_lost
      on_error: log.error

    @_top_gap = padding_box.top_padding + border_box.top_padding
    @_bottom_gap = padding_box.bottom_padding + border_box.bottom_padding
    @_left_gap = padding_box.left_padding + border_box.left_padding
    @_right_gap = padding_box.right_padding + border_box.right_padding

  _set_appearance: =>
    with @sci
      \set_hscroll_bar false
      \set_vscroll_bar false
    @height_rows = 1

  @property width_cols:
    get: =>
      char_width = @sci\text_width(Scintilla.STYLE_LINENUMBER, 'm')
      return math.floor @gsci.allocated_width / char_width

  @property height:
    get: => @_height
    set: (val) =>
      -- round to multiple of row-height
      @height_rows = math.floor val / @sci\text_height(0)

  @property padded_height: get: => @height + @_top_gap + @_bottom_gap

  @property height_rows:
    get: => @_height_rows
    set: (rows) =>
      @_height_rows = rows
      @_set_height rows * @sci\text_height(0)

  @property width:
    get: => @_width or @gsci.allocated_width
    set: (val) => @_set_width val

  @property padded_width: get: => @width + @_left_gap + @_right_gap

  @property row_height:
    get: => @sci\text_height 0

  _set_height: (height) =>
    @_height = height
    @gsci\set_size_request -1, height

  _set_width: (width) =>
    @_width = width
    @gsci\set_size_request width, -1

  adjust_width_to_fit: =>
    char_width = @sci\text_width 32, ' '
    max_line = 0
    max_line = math.max(#line, max_line) for line in *@buffer.lines
    @width = (max_line * char_width) + (char_width / 2)

  to_gobject: => @box

  @property text:
    get: => @buffer.text
    set: (text) => @buffer.text = text

  @property is_focus:
    get: => @sci\to_gobject!.is_focus

  focus: => @sci\grab_focus!

  delete_back: => @sci\delete_back!

  show: =>
    @to_gobject!\show_all!
    @text = @opts.text if @opts.text
    @showing = true

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


