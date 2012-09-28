import Gtk from lgi
import Scintilla, keyhandler, config from lunar
import PropertyObject from lunar.aux.moon
import style, theme, Cursor, Selection, ActionBuffer, List from lunar.ui

completion_text = (item) ->
  type(item) == 'table' and item[1] or item

class Readline extends PropertyObject
  new: (window) =>
    @window = window
    @bin = Gtk.Box orientation: 'HORIZONTAL'
    @showing = false
    super!

  show: =>
    if not @box then @_instantiate!

    @last_focused = @window\get_focus!
    @window.status\hide!
    @sci\grab_focus!
    @bin\show_all!
    @showing = true

  hide: =>
    if @showing
      @bin\hide!
      @showing = false
      @buffer.text = ''
      @_adjust_height!
      @window.status\show!
      @last_focused\grab_focus! if @last_focused

  read: (prompt, input = {}, callback) =>
    input = input! if callable input
    @show! if not @showing
    @prompt = prompt or ''
    @input = input
    @callback = callback
    @text = ''
    @completion_unwanted = false
    @_complete!

  to_gobject: => @bin

  @property prompt:
    get: => @_prompt
    set: (prompt) =>
      @_prompt = tostring(prompt)
      @text = ''

  @property text:
    get: =>
      text = @buffer.lines[#@buffer.lines]
      text\sub #@prompt + 1
    set: (text) =>
      @buffer.text = @prompt .. text
      @_adjust_height!
      @cursor\eof!

  _at_start: => @cursor.column <= #@prompt + 1

  _complete: (force) =>
    @_remove_completions!
    text = @text
    return if @completion_unwanted
    config_says_complete = config.complete == 'always'
    input_says_complete = @input.should_complete and @input\should_complete text, self
    should_complete = force or config_says_complete or input_says_complete

    completions, options = if should_complete and @input.complete then @input\complete text, self
    count = completions and #completions or 0
    if count > 0
      @completion_list = List @buffer, 1
      list_options = options and options.list or {}
      with @completion_list
        .items = completions
        .max_height = @_max_list_lines!
        .selection_enabled = true
        @completion_list[k] = v for k, v in pairs list_options
        \show!
      @_adjust_height!

  _adjust_height: =>
    @gsci.height = @sci\text_height(0) * #@buffer.lines

  _remove_completions: =>
    if @completion_list
      @completion_list\clear!
      @_adjust_height!
      @completion_list = nil

  _update_input: =>
    if @input and @input.update then @input\update @text, self

  _max_list_lines: =>
    win_lines = @window.height / @sci\text_height 0
    max_lines = math.floor win_lines - win_lines * 0.3 -- max occupation two thirds
    max_lines

  _on_keypress: (event) =>
    return true if keyhandler.dispatch event, { @keymap }, self
    return event.character == nil or event.ctrl or event.alt

  _on_char_added: (event) =>
    @_update_input!
    @_complete @completion_list != nil

  _instantiate: =>
    @sci = Scintilla!
    @sci\set_style_bits 8
    @sci\set_lexer Scintilla.SCLEX_NULL
    @cursor = Cursor @sci, Selection @sci
    @buffer = ActionBuffer @sci
    @gsci = @sci\get_gobject!
    @box = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 1,
        left_padding: 1,
        right_padding: 3,
        bottom_padding: 3,
        @gsci
      }
    }
    @box.hexpand = true
    @gsci\get_style_context!\add_class 'readline'
    @box\get_style_context!\add_class 'readline_box'
    @_set_appearance!
    @bin\add @box

    @sci.on_keypress = self\_on_keypress
    @sci.on_char_added = self\_on_char_added

  _set_appearance: =>
    style.register_sci @sci

    with @sci
      \set_hscroll_bar false
      \set_vscroll_bar false
      \set_margin_width_n 1, 0 -- fold margin
      @gsci.height = \text_height(0)

    v = theme.current.editor
    -- caret
    c_color = '#000000'
    c_width = 1

    if v.caret
      c_color = v.caret.color if v.caret.color
      c_width = v.caret.width if v.caret.width

    @sci\set_caret_fore c_color
    @sci\set_caret_width c_width

  _select_next: => @completion_list and @completion_list\select_next!
  _select_prev: => @completion_list and @completion_list\select_prev!
  _next_page: => @completion_list and @completion_list\next_page!
  _prev_page: => @completion_list and @completion_list\prev_page!

  _submit: =>
    value = @text

    if @completion_list
      item = @completion_list.selection
      @_remove_completions!
      value = completion_text item
      @text = @text\gsub('%a+$', '') .. value
      @_update_input!
      if @input.on_completed and @input\on_completed(item) == false
        @_complete!
        return

    value = @input\value_for value if @input.value_for
    status, ret = pcall self.callback, value, self
    if not status
      @hide!
      error ret

    if ret != false
      @hide!
    else
      @_complete!

  keymap: {
    escape: =>
      if @completion_list
        @_remove_completions!
        @completion_unwanted = true
      else
        @hide!

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
        @_remove_completions!
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
