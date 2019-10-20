-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
require 'howl.ui.icons.font_awesome'
import bindings, dispatch from howl
import PropertyObject from howl.util.moon
import NotificationWidget, BufferPopup, TextWidget, IndicatorBar, ContentBox, HelpContext, style from howl.ui

append = table.insert

style.define_default 'prompt', 'keyword'

class CommandLine extends PropertyObject
  new: (@window) =>
    super!
    @def = {}

    @bin = Gtk.Box Gtk.ORIENTATION_HORIZONTAL
    @box = nil
    @command_widget = nil
    @header = nil
    @indic_title = nil
    @indic_info = nil
    @is_open = false
    @is_hidden = false

    @_help_context = nil
    @_title = nil
    @_prompt = ''
    @_widgets = {}  -- maps string name to widget object

  to_gobject: => @bin

  _initialize_box: =>
    @box = Gtk.Box Gtk.ORIENTATION_VERTICAL

    @command_widget = TextWidget
      line_wrap: 'char'
      on_keypress: (event) ->
        result = true
        if not @handle_keypress(event)
          result = false
        @post_keypress!
        return result
      on_changed: ->
        @handle_text_change!
      on_focus_lost: ->
        -- don't let focus leave command line, even if user clicks the editor, we'll grab focus back while open
        if @is_open and not @is_hidden and howl.activities.nr_visible == 0
          @command_widget\focus!

    @command_widget.visible_rows = 1
    @box\pack_end @command_widget\to_gobject!, false, 0, 0

    @notification = NotificationWidget!
    @box\pack_end @notification\to_gobject!, false, 0, 0

    @header = IndicatorBar 'header'
    @indic_title = @header\add 'left', 'title'
    @indic_info = @header\add 'right', 'info'

    @box.margin_left = 2
    @box.margin_top = 2
    c_box = ContentBox 'command_line', @box, {
      header: @header\to_gobject!
    }
    @bin\add c_box\to_gobject!

  _destroy_box: =>
    @box\destroy!
    @box = nil

  @property title:
    get: => @_title
    set: (text) =>
      @_title = text
      if text == nil or text.is_empty
        @header\to_gobject!\hide!
      else
        @header\to_gobject!\show!
        @indic_title.label = tostring text

  @property prompt:
    get: => @_prompt or ''
    set: (prompt='') =>
      @command_widget\delete 1, @_prompt_end
      @command_widget\insert prompt, 1, 'prompt'
      @_prompt = prompt
      @_cursor_to_end!

  @property _prompt_end:
    get: => if @_prompt then @_prompt.ulen else 0

  @property text:
    get: => @command_widget.text\usub 1 + @_prompt_end
    set: (text) =>
      @clear!
      @write text

  clear: =>
    @command_widget\delete 1 + @_prompt_end, @command_widget.text.ulen
    @\_cursor_to_end!

  write: (text) =>
    @command_widget\append text
    @\_cursor_to_end!
    @\handle_text_change!

  _cursor_to_end: =>
    @command_widget.cursor\eof!

  post_keypress: =>
    @_enforce_left_pos!

  _enforce_left_pos: =>
    -- don't allow cursor to go left into prompt
    left_pos = @_prompt_end + 1
    if @command_widget.cursor.pos < left_pos
      @command_widget.cursor.pos = left_pos

  handle_text_change: =>
    @command_widget\adjust_height! -- expand or contract on wrapping
    return unless @def.on_text_changed
    -- avoid deep recursive calls to short circuit cyclic bugs in the code
    @_update_recursive_count or= 0
    @_update_recursive_count += 1
    if @_update_recursive_count > 1000
      error 'command line hit on_text_changed recursion limit'
    ok, err = pcall -> @def\on_text_changed @text
    @_update_recursive_count -= 1
    error err unless ok

  handle_keypress: (event) =>
    -- keymaps checked in order:
    --   @preemptive_keymap - command line keystrokes that cannot be remapped
    --   @opts.cancel_for_keymap - if dispatch is successful, this command_line is cancelled
    --   @def.keymap - keymap provided by definition table passed into run()
    --   @default_keymap - standard keys such ask arrows and backspace
    return true if bindings.dispatch event, 'command_line', { @preemptive_keymap }, self

    @window.status\clear!
    @close_help!

    if @opts.cancel_for_keymap and bindings.can_dispatch event, 'command_line', { @opts.cancel_for_keymap }
      text = @text
      @finish!
      bindings.dispatch event, 'command_line', { @opts.cancel_for_keymap }, :text
      return true

    if @def and @def.keymap
      return true if bindings.dispatch event, 'command_line', { @def.keymap }, @def

    return true if bindings.dispatch event, 'command_line', { @default_keymap }, self

    return false

  preemptive_keymap:
    ctrl_shift_backspace: => @finish! if @parking
    escape: =>
      if @help_popup
        @close_help!
        return true
      return false

  default_keymap:
    f1: => @show_help!

    binding_for:
      ["cursor-home"]: => @command_widget.cursor.pos = @_prompt_end
      ["cursor-line-end"]: => @_cursor_to_end!
      ["cursor-left"]: => @command_widget.cursor\left!
      ["cursor-right"]: => @command_widget.cursor\right!
      ["editor-delete-back"]: =>
        if @command_widget.cursor.pos <= @_prompt_end + 1
          -- backspace attempted into prompt
          if @def.handle_back
            @def\handle_back!
            return true
          else
            return true

        range_start = @command_widget.selection\range!
        return if range_start and range_start < @_prompt_end
        @command_widget\delete_back!

      ["editor-paste"]: =>
        import clipboard from howl
        if clipboard.current
          @write clipboard.current.text

  add_widget: (name, widget, pos='bottom') =>
    error('No widget provided', 2) if not widget

    @remove_widget name

    local pack
    if pos == 'bottom'
        pack = @box\pack_end
    elseif pos == 'top'
        pack = @box\pack_start
    else
        error "Invalid pos #{pos}"
    pack widget\to_gobject!, false, 0, 0
    @_widgets[name] = widget

    widget\show!

  remove_widget: (name) =>
    widget = @_widgets[name]
    return unless widget
    widget\to_gobject!\destroy!
    @_widgets[name] = nil

  get_widget: (name) => @_widgets[name]

  clear_widgets: =>
    names = [name for name, _ in pairs @_widgets]
    for name in *names
      @remove_widget name


  load_help: =>
    -- merge help provided by @def and @opts
    @_help_context = HelpContext!
    if @opts.help
      @_help_context\merge @opts.help
    def_help = @def.get_help and @def\get_help!
    if def_help
      @_help_context\merge def_help

    -- when help is available, show help info/keyboard icons in header
    info_icon = howl.ui.icon.get('font-awesome-info')
    keyboard_icon = howl.ui.icon.get('font-awesome-keyboard-o')
    text = ''

    if #@_help_context.sections > 0
      text = info_icon.text

    if #@_help_context.keys > 0
      text ..= " #{keyboard_icon.text}"

    unless text.is_empty
      text ..= ': f1'

    @indic_info.label = text


  show_help: =>
    help_buffer = @_help_context\get_buffer!
    return unless help_buffer and not help_buffer.text.is_blank

    -- display help buffer in a centered popup
    popup = BufferPopup help_buffer
    @close_help!
    popup\show howl.app.window\to_gobject!, x:1, y:1
    popup\center!
    @help_popup = popup

  close_help: =>
    if @help_popup
      @help_popup\destroy!
      @help_popup = nil

  open: =>
    return if @is_open

    @bin\show_all!
    @notification\hide!
    @title = @title

    @is_open = true
    @is_hidden = false

    @command_widget\focus!

  hide: =>
    @bin\hide!
    @is_hidden = true

  unhide: =>
    @bin\show!
    @is_hidden = false
    @command_widget\focus!

  close: =>
    return if not @box
    if @def.on_close
      @def\on_close!
    @reset!
    if @is_open
      @bin\hide!
      @_destroy_box!
      @is_open = false

  reset: =>
    @def = {}
    @parking = nil
    @title = ''
    @prompt = ''
    @text = ''

  run: (def, opts={}) =>
    error 'def not provided' unless def
    error 'def.init not provided' unless def.init
    @_initialize_box! unless @box
    @def = def
    @opts = moon.copy opts
    @load_help!
    @parking = dispatch.park 'command_line'
    status, err = pcall -> def\init self, max_height: @window.allocated_height * 0.5, max_width: @window.allocated_width - 20
    unless status
      log.error 'def.init returned error: ', :err
    @open!

    -- calls @def.on_text_changed
    dispatch.launch -> @text = opts.text or ''

    result = dispatch.wait @parking
    @close!
    return result

  finish: (result) =>
    error 'no handler to finish' unless @parking
    dispatch.resume @parking, result

class CommandPanel extends PropertyObject
  new: (@window) =>
    super!
    @command_lines = {}
    @bin = Gtk.Box Gtk.ORIENTATION_VERTICAL

  to_gobject: => @bin

  @property is_active: get: => #@command_lines > 0
  @property active_command_line: get: => @command_lines[#@command_lines]

  _push: (command_line) =>
    @bin\pack_end command_line\to_gobject!, false, 0, 0
    append @command_lines, command_line

  _remove: (command_line) =>
    before_count = #@command_lines
    @command_lines = [cl for cl in *@command_lines when cl != command_line]
    after_count = #@command_lines
    if after_count < before_count
      @bin\remove command_line\to_gobject!
      return command_line

  run: (def, opts={}) =>
    current_command_line = @command_lines[#@command_lines]  -- currently active command line
    unless current_command_line
      -- first command line, save focus of current editor
      @last_focused = @window.focus if not @last_focused
      @window\remember_focus!

    if current_command_line
      -- hide currently active command line
      -- this should also hide all related widgets because they're in the same bin
      -- *important*: this should always happen before we run the new command
      -- line otherwise both command_lines will fight for the focus (see
      -- on_focus_lost)
      current_command_line\hide!
    else
      @window.status\hide!
      @bin\show!

    -- create the new command line and run it
    command_line = CommandLine @window
    @_push command_line
    result = table.pack command_line\run def, opts
    @_remove command_line

    -- after the run, revert to previous state
    if current_command_line
      -- re display the previous command line
      current_command_line\unhide!
    else
      -- no more command lines, close up the entire panel
      @bin\hide!
      @last_focused\grab_focus! if @last_focused
      @last_focused = nil
      @window.status\show!

    return table.unpack result

  notify: (message, level) =>
    return unless @is_active
    with @active_command_line.notification
      \notify level, message
      \show!

  cancel: =>
    command_lines = [command_line for _, command_line in ipairs @command_lines]
    dispatch.launch ->
      for idx = #command_lines, 1, -1
        command_lines[idx]\finish!

return CommandPanel

