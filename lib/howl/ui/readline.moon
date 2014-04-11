-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

Gtk = require 'ljglibs.gtk'
import Scintilla, bindings, config, inputs from howl
import PropertyObject from howl.aux.moon
import style, theme, Cursor, Selection, ActionBuffer, List, IndicatorBar from howl.ui

completion_text = (item) ->
  type(item) == 'table' and item[1] or item

shorten = (text, length) ->
  length = 10 if length < 10
  local short
  significant_end = text\ufind ' '
  if significant_end and length - significant_end > 10
    short = text\usub(1, significant_end) .. '[..]'
  else
    short = '[..]'

  short .. text\usub(text.ulen - (length - short.ulen))

class Readline extends PropertyObject
  new: (@window) =>
    @bin = Gtk.Box!
    @showing = false
    @session_id = 0
    super!

  show: =>
    if not @box then @_instantiate!

    @last_focused = @window.focus
    @window.status\hide!
    @window\_remember_focus!
    @sci\grab_focus!
    @bin\show_all!
    @showing = true
    @min_list_height = 0

  hide: =>
    if @showing
      has_focus = @sci\to_gobject!.is_focus

      @bin\hide!
      @showing = false
      @buffer.text = ''
      @_adjust_height!
      @completion_list = nil
      @notification = nil
      @width_in_columns = nil
      @window.status\show!

      @last_focused\grab_focus! if @last_focused and has_focus

  read: (prompt, input = {}, opts = {}) =>
    @co, is_main = coroutine.running!
    error "Cannot invoke Readline.read() from the main coroutine", 2 if is_main
    input = inputs[input] if type(input) == 'string'
    input = input! if callable input
    @session_id += 1
    @show! if not @showing
    @prompt = prompt or ''
    @title = input.title or ''
    @input = input
    @text = opts.text or ''
    @completion_unwanted = false
    @seen_interaction = false
    @_update_input! unless @text.is_blank
    @_complete!
    coroutine.yield!

  notify: (text, style = 'info') =>
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
      @_prompt_len = @_prompt.ulen
      @text = ''

  @property text:
    get: =>
      text = @buffer.lines[#@buffer.lines]
      text\usub @_prompt_len + 1
    set: (text) =>
      prompt = @prompt
      if @width_in_columns and @width_in_columns - prompt.ulen < 10
        prompt = shorten prompt, @width_in_columns - 10

      @_prompt_len = prompt.ulen
      @buffer.lines[#@buffer.lines].text = prompt .. text
      @_adjust_height!
      @cursor\eof!
      @sci\set_xoffset 0

  @property title:
    get: => @indic_title.label
    set: (text) =>
      if text == nil or #text == 0
        @header\to_gobject!\hide!
      else
        @header\to_gobject!\show!
        @indic_title.label = tostring text

  _at_start: => @cursor.column <= @_prompt_len + 1

  _complete: (opts = {}) =>
    @_show_only_cmd_line!
    text = @text
    return if @completion_unwanted
    config_says_complete = config.complete == 'always'
    input_says_complete = @input.should_complete and @input\should_complete self
    should_complete = opts.force or config_says_complete or input_says_complete

    completions, options = if should_complete and @input.complete then @input\complete text, self, opts.type
    options or= {}
    count = completions and #completions or 0
    @title = options.title if options.title
    list_position = 1
    list_position = @buffer\insert "#{options.caption}\n\n", 1 if options.caption

    if count > 0
      @completion_list = List @buffer, list_position
      list_options = options.list or {}
      with @completion_list
        .items = completions
        .max_height = @_max_list_lines!
        .min_height = @min_list_height
        .filler_text = '~'
        .selection_enabled = true
        .highlight_matches_for = text
        @completion_list[k] = v for k, v in pairs list_options
        \show!
        @min_list_height = math.max .height, @min_list_height

      if options.select_last
        @completion_list\select #@completion_list.items

    @_adjust_height!
    @_selection_changed!

  _adjust_height: =>
    @gsci\set_size_request -1, @sci\text_height(0) * #@buffer.lines

  _show_only_cmd_line: =>
    @buffer.lines\delete 1, #@buffer.lines - 1
    @notification = nil
    @completion_list = nil
    @_adjust_height!

  _update_input: =>
    if @input and @input.update then @input\update @text, self

  _max_list_lines: =>
    win_lines = @window.allocated_height / @sci\text_height 0
    max_lines = math.floor win_lines - (win_lines * 0.5) -- max occupation half of estate
    max_lines

  _on_keypress: (event) =>
    return true if bindings.dispatch event, 'readline', { @keymap }, self
    return event.character == nil or event.ctrl or event.alt

  _on_user_added_text: =>
    @seen_interaction = true
    @_update_input!
    @_complete force: @completion_list != nil

  _on_error: (err) =>
    @notify err, 'error'

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
    @gsci\on_size_allocate ->
      unless @width_in_columns
        char_width = @sci\text_width(Scintilla.STYLE_LINENUMBER, 'm')
        @width_in_columns = math.floor @gsci.allocated_width / char_width
        @text = @text

    sci_container = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 3,
        left_padding: 3,
        right_padding: 3,
        bottom_padding: 3,
        @gsci
      }
    }
    sci_container.style_context\add_class 'sci_container'

    sci_box = Gtk.EventBox {
      hexpand: true
      Gtk.Alignment {
        top_padding: 1,
        bottom_padding: 1,
        sci_container
      }
    }
    sci_box.style_context\add_class 'sci_box'

    @box = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 1,
        left_padding: 1,
        right_padding: 3,
        bottom_padding: 3,
        Gtk.Box Gtk.ORIENTATION_VERTICAL, {
          @header\to_gobject!
          {
            expand: false
            sci_box
          }
        }
      }
    }

    @box.style_context\add_class 'readline_box'
    theme.register_background_widget @box
    theme.register_background_widget @gsci
    @_set_appearance!
    @bin\add @box

    @sci.listener =
      on_keypress: self\_on_keypress
      on_char_added: self\_on_user_added_text
      on_text_inserted: @buffer\_on_text_inserted
      on_text_deleted: @buffer\_on_text_deleted
      on_error: self\_on_error

    style.register_sci @sci
    theme.register_sci @sci

  _set_appearance: =>
    with @sci
      \set_hscroll_bar false
      \set_vscroll_bar false
      @gsci\set_size_request -1, \text_height(0)

  _select_next: =>
    if @completion_list
      @completion_list\select_next!
      @_selection_changed!

  _select_prev: =>
    if @completion_list
      @completion_list\select_prev!
      @_selection_changed!
    else
      @_complete force: true, type: 'history'

  _next_page: =>
    if @completion_list
      @completion_list\next_page!
    @_selection_changed!

  _prev_page: =>
    if @completion_list
      @completion_list\prev_page!
      @_selection_changed!

  _selection_changed: =>
    if @input.on_selection_changed and @completion_list
      @input\on_selection_changed @completion_list.selection, self

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
      @_complete!
      return

    values = { value, n: 1 }
    values = table.pack @input\value_for value if @input.value_for
    @_show_only_cmd_line!
    session_id = @session_id
    status, error = coroutine.resume @co, table.unpack(values, 1, values.n)
    unless status
      _G.log.error "Error invoking readline handler for '#{@prompt}#{@text}': #{error}"

    @hide! if session_id == @session_id

  _cancel: =>
    if @completion_list or @notification
      @_show_only_cmd_line!
      @completion_unwanted = true
      input_wants_close = @input.close_on_cancel and @input\close_on_cancel self
      return if @seen_interaction and not input_wants_close

    @input\on_cancelled self if @input.on_cancelled
    @hide!
    coroutine.resume @co, nil

  keymap: {
    escape: => @_cancel!
    ctrl_c: => @_cancel!
    ctrl_g: => @_cancel!
    ctrl_v: =>
      @sci\paste!
      @_on_user_added_text!

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
        @_complete force: complete_again
      else if @input.go_back
        @_show_only_cmd_line!
        @input\go_back self
        @_complete force: complete_again

    return: => @_submit!

    tab: =>
      if @completion_list then @_next_page!
      else
        @completion_unwanted = false
        @_complete force: true

    shift_tab: => @_prev_page!
  }

return Readline
