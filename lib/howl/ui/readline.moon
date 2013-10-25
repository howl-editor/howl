-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import Gtk, Gdk from lgi
import Scintilla, keyhandler, config, inputs from howl
import PropertyObject from howl.aux.moon
import style, theme, Cursor, Selection, ActionBuffer, List, IndicatorBar from howl.ui

completion_text = (item) ->
  type(item) == 'table' and item[1] or item

class Readline extends PropertyObject
  new: (@window) =>
    @bin = Gtk.Box orientation: 'HORIZONTAL'
    @showing = false
    super!

  show: =>
    if not @box then @_instantiate!

    background = Gdk.RGBA!
    background\parse style.default.background
    @box\override_background_color 0, background

    @last_focused = @window\get_focus!
    @window.status\hide!
    @window\_remember_focus!
    @sci\grab_focus!
    @bin\show_all!
    @showing = true

  hide: =>
    if @showing
      has_focus = @sci\to_gobject!.is_focus

      @bin\hide!
      @showing = false
      @buffer.text = ''
      @_adjust_height!
      @completion_list = nil
      @notification = nil
      @window.status\show!

      @last_focused\grab_focus! if @last_focused and has_focus

  read: (prompt, input = {}, callback) =>
    error 'Missing parameter "callback"', 2 unless callback
    input = inputs[input] if type(input) == 'string'
    input = input! if callable input
    @show! if not @showing
    @prompt = prompt or ''
    @title = input.title or ''
    @input = input
    @callback = callback
    @text = ''
    @completion_unwanted = false
    @seen_interaction = false
    @_complete!

  notify: (text, style) =>
    @notification\delete! if @notification
    start_pos = @completion_list and @completion_list.end_pos or 1
    text ..= '\n' unless text\match '[\n\r]$'
    @buffer\insert text, start_pos, style
    @notification = @buffer\chunk start_pos, #text
    @_adjust_height!

  to_gobject: => @bin

  @property prompt:
    get: => @_prompt
    set: (prompt) =>
      @_prompt = tostring(prompt)
      @text = ''

  @property text:
    get: =>
      text = @buffer.lines[#@buffer.lines]
      text\usub #@prompt + 1
    set: (text) =>
      @buffer.text = @prompt .. text
      @_adjust_height!
      @cursor\eof!

  @property title:
    get: => @indic_title.label
    set: (text) =>
      if text == nil or #text == 0
        @header\to_gobject!\hide!
      else
        @header\to_gobject!\show!
        @indic_title.label = tostring text

  _at_start: => @cursor.column <= #@prompt + 1

  _complete: (force) =>
    @_show_only_cmd_line!
    text = @text
    return if @completion_unwanted
    config_says_complete = config.complete == 'always'
    input_says_complete = @input.should_complete and @input\should_complete text, self
    should_complete = force or config_says_complete or input_says_complete

    completions, options = if should_complete and @input.complete then @input\complete text, self
    options or= {}
    count = completions and #completions or 0
    @title = options.title if options.title
    list_position = 1
    list_position = @buffer\insert "#{options.caption}\n\n", 1 if options.caption
    if count > 0
      @completion_list = List @buffer, list_position
      list_options = options and options.list or {}
      with @completion_list
        .items = completions
        .max_height = @_max_list_lines!
        .selection_enabled = true
        @completion_list[k] = v for k, v in pairs list_options
        @completion_list.highlight_matches_for = text unless list_options.highlight_matches_for != nil
        \show!

    @_adjust_height!

  _adjust_height: =>
    @gsci.height = @sci\text_height(0) * #@buffer.lines

  _show_only_cmd_line: =>
    @buffer.lines\delete 1, #@buffer.lines - 1
    @notification = nil
    @completion_list = nil
    @_adjust_height!

  _update_input: =>
    if @input and @input.update then @input\update @text, self

  _max_list_lines: =>
    win_lines = @window.height / @sci\text_height 0
    max_lines = math.floor win_lines - (win_lines * 0.5) -- max occupation half of estate
    max_lines

  _on_keypress: (event) =>
    return true if keyhandler.dispatch event, { @keymap }, self
    return event.character == nil or event.ctrl or event.alt

  _on_char_added: (event) =>
    @seen_interaction = true
    @_update_input!
    @_complete @completion_list != nil

  _on_error: (err) => @notify err, 'error'

  _instantiate: =>
    @sci = Scintilla!
    @sci\set_style_bits 8
    @sci\set_lexer Scintilla.SCLEX_NULL
    @sci\clear_all_cmd_keys!
    @cursor = Cursor self, Selection @sci
    @buffer = ActionBuffer @sci
    @buffer.title = 'readline'
    @gsci = @sci\to_gobject!
    @header = IndicatorBar 'header', 3
    @indic_title = @header\add 'left', 'title'
    @box = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 1,
        left_padding: 1,
        right_padding: 3,
        bottom_padding: 3,
        Gtk.Box {
          orientation: 'VERTICAL',
          @header\to_gobject!
          {
            expand: false
            Gtk.EventBox {
              id: 'sci_box'
              hexpand: true
              Gtk.Alignment {
                top_padding: 1,
                bottom_padding: 1,
                Gtk.EventBox {
                  id: 'sci_container'
                  Gtk.Alignment {
                    top_padding: 3,
                    left_padding: 3,
                    right_padding: 3,
                    bottom_padding: 3,
                    @gsci
                  }
                }
              }
            }
          }
        }
      }
    }

    @box\get_style_context!\add_class 'readline_box'
    @box.child.sci_box\get_style_context!\add_class 'sci_box'
    @box.child.sci_container\get_style_context!\add_class 'sci_container'
    @_set_appearance!
    @bin\add @box

    @sci.listener =
      on_keypress: self\_on_keypress
      on_char_added: self\_on_char_added
      on_text_inserted: @buffer\_on_text_inserted
      on_text_deleted: @buffer\_on_text_deleted
      on_error: self\_on_error

    style.register_sci @sci
    theme.register_sci @sci

  _set_appearance: =>
    with @sci
      \set_hscroll_bar false
      \set_vscroll_bar false
      @gsci.height = \text_height(0)

  _select_next: => @completion_list and @completion_list\select_next!
  _select_prev: => @completion_list and @completion_list\select_prev!
  _next_page: => @completion_list and @completion_list\next_page!
  _prev_page: => @completion_list and @completion_list\prev_page!

  _submit: =>
    value = @text

    if @completion_list
      item = @completion_list.selection
      @_show_only_cmd_line!
      value = completion_text item
      @text = @text\gsub('[^%s=]+$', '') .. value
      @_update_input!
      if @input.on_completed and @input\on_completed(item, self) == false
        @_complete!
        return

    if @input.on_submit and @input\on_submit(value, self) == false
      return

    value = @input\value_for value if @input.value_for
    @_show_only_cmd_line!
    status, ret = pcall self.callback, value, self
    if not status
      @hide!
      error ret

    if ret != false
      @hide!
    else
      @_complete!

  _cancel: =>
    if @completion_list or @notification
      @_show_only_cmd_line!
      @completion_unwanted = true
      input_wants_close = @input.close_on_cancel and @input\close_on_cancel!
      return if @seen_interaction and not input_wants_close

    status, err = pcall self.callback, nil, self
    @hide!
    error(err) if not status

  keymap: {
    escape: => @_cancel!
    ctrl_c: => @_cancel!
    ctrl_g: => @_cancel!

    left: => @cursor\left! if not @_at_start!
    right: => @cursor\right!

    down: => @_select_next!
    up: => @_select_prev!

    ctrl_n: => @_select_next!
    ctrl_p: => @_select_prev!

    page_down: => @_next_page!
    page_up: => @_prev_page!

    alt_n: => @_next_page!
    alt_p: => @_prev_page!

    backspace: =>
      complete_again = @completion_list != nil
      if not @_at_start!
        @sci\delete_back!
        @_update_input!
        @_complete complete_again
      else if @input.go_back
        @_show_only_cmd_line!
        @input\go_back self
        @_complete complete_again

    return: => @_submit!

    tab: =>
      if @completion_list then @_next_page!
      else
        @completion_unwanted = false
        @_complete true

    shift_tab: => @_prev_page!
  }

return Readline
