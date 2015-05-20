-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
import Scintilla, bindings, log from howl
import PropertyObject from howl.aux.moon
import style, theme, Cursor, Selection, ActionBuffer, IndicatorBar from howl.ui

class TextWidget extends PropertyObject
  new: (@opts={}) =>
    super!
    @_init_sci!

  _init_sci: =>
    @sci = Scintilla!
    @sci\set_style_bits 8
    @sci\set_wrap_mode  @opts.line_wrapping == 'char' and Scintilla.SC_WRAP_CHAR or Scintilla.SC_WRAP_NONE
    @sci\set_lexer Scintilla.SCLEX_NULL
    @sci\clear_all_cmd_keys!
    @cursor = Cursor self, Selection @sci

    @buffer = ActionBuffer @sci
    @buffer.text = ''
    @buffer.title = 'SciBox'

    @gsci = @sci\to_gobject!

    @gsci\on_map -> @_on_map!

    sci_container = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: @opts.top_padding or 3,
        left_padding: @opts.left_padding or 3,
        right_padding: @opts.right_padding or 1,
        bottom_padding: @opts.bottom_padding or 1,
        @gsci
      }
    }
    sci_container.style_context\add_class 'sci_container'

    @box = Gtk.EventBox {
      hexpand: true
      Gtk.Alignment {
        top_padding: @opts.top_border or 1,
        bottom_padding: @opts.bottom_border or 0,
        sci_container
      }
    }
    @box.style_context\add_class 'sci_box'

    theme.register_background_widget @gsci
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

    style.register_sci @sci
    theme.register_sci @sci

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

  @property height_rows:
    get: => @_height_rows
    set: (rows) =>
      @_height_rows = rows
      @_set_height rows * @sci\text_height(0)

  @property row_height:
    get: => @sci\text_height 0

  _set_height: (height) =>
    @_height = height
    @gsci\set_size_request -1, height

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


