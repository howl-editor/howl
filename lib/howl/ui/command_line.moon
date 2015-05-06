-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
import bindings, dispatch, interact, signal from howl
import Matcher from howl.util
import PropertyObject from howl.aux.moon
import TextWidget, NotificationWidget, IndicatorBar, StyledText from howl.ui
import highlight, markup, style, theme from howl.ui

-- used to generate a unique id for every new activity
id_counter = 0

class CommandLine extends PropertyObject
  new: (@window) =>
    super!
    @bin = Gtk.Box Gtk.ORIENTATION_HORIZONTAL
    @box = nil
    @command_widget = nil
    @notification_widget = nil
    @header = nil
    @indic_title = nil
    @showing = false
    @spillover = nil
    @running = {}
    @_command_history = {}
    @aborted = {}
    @next_run_queue = {}

  @property current: get: => @running[#@running]

  @property stack_depth: get: => #@running

  @property command_history: get: => moon.copy @_command_history

  _init_activity_from_factory: (activity_frame) =>
      activity = activity_frame.activity_spec.factory!
      if not activity
        error "activity '#{activity_frame.name}' factory returned nil"

      activity_frame.activity = activity

      parked_handle = dispatch.park 'activity'
      activity_frame.parked_handle = parked_handle

      finish = (...) ->
        results = table.pack ...
        activity_frame.results = results
        @_finish(activity_frame.activity_id, results)
        dispatch.launch -> dispatch.resume parked_handle
        true  -- finish() is often the last function in a key handler

      activity_frame.runner = ->
        table.pack activity\run(finish, unpack activity_frame.args)

        -- check that run didn't call finish
        if @current and @current.activity_id == activity_frame.activity_id
          @current.state = 'running'
          @show!
          bindings.cancel_capture!
          if @spillover
            @write @spillover if not @spillover.is_empty
            @spillover = nil

        dispatch.wait parked_handle

  _init_activity_from_handler: (activity_frame) =>
      if not callable activity_frame.activity_spec.handler
        error "activity '#{activity_frame.name}' handler is not callable"

      activity = { handler: activity_frame.activity_spec.handler }

      activity_frame.activity = activity

      activity_frame.runner = ->
        @current.state = 'running'
        results = table.pack activity.handler(unpack activity_frame.args)
        if @current and @current.activity_id == activity_frame.activity_id
          activity_frame.results = results
          @_finish(activity_frame.activity_id, results)

  run: (activity_spec, ...) =>
    if not activity_spec.name or not (activity_spec.handler or activity_spec.factory)
      error 'activity_spec requires "name" and one of "handler" or "factory" fields'

    id_counter += 1
    activity_id = id_counter

    activity_frame = {
      name: activity_spec.name
      :activity_id
      :activity_spec
      args: table.pack ...
      state: 'starting'
      results: {}
    }

    if activity_spec.factory
      @_init_activity_from_factory activity_frame
    else
      @_init_activity_from_handler activity_frame

    table.insert @running, activity_frame

    @_initialize! if not @box

    with @current
      .command_line_left_stop = @command_widget.text.ulen + 1
      .command_line_widgets = { }
      .command_line_prompt_len = 0

    if @stack_depth == 1
      @current.evade_history = activity_spec.evade_history
      @history_recorded = false
    else
      previous = @running[@stack_depth - 1]
      @current.evade_history = previous.evade_history or activity_spec.evade_history

    bindings.capture -> false
    ok, err = pcall activity_frame.runner
    bindings.cancel_capture!

    unless ok
      if @current and activity_id == @current.activity_id
        @_finish(activity_id)
      log.error err
      return

    unpack activity_frame.results

  run_after_finish: (f) =>
    if not (@stack_depth > 0)
      error 'Cannot run_after_finish - no running activity'
    table.insert @next_run_queue, f

  _process_run_after_finish: =>
    while true
      f = table.remove @next_run_queue, 1
      break unless f
      f!

  _is_active: (activity_id) =>
    for activity in *@running
      if activity.activity_id == activity_id
        return true
    return false

  _finish: (activity_id, results={}) =>
    if @aborted[activity_id]
      @aborted[activity_id] = nil
      return
    if not @current
      error 'Cannot finish - no running activities'

    if activity_id != @current.activity_id
      if @_is_active activity_id
        while @current.activity_id != activity_id
          @_abort_current!
      else
        error "Cannot finish - invalid activity_id #{activity_id}"

    @current.state = 'stopping'

    if #results > 0
      @record_history!

    @clear!
    @prompt = nil

    for name, _ in pairs @_widgets
      @remove_widget name

    if @current.saved_command_line
      @command_widget\insert @current.saved_command_line, 1
      @current.saved_command_line = nil

    @running[#@running] = nil

    if @stack_depth > 0
      @title = @title
    else
      @hide!
      @pop_spillover!
      @_process_run_after_finish!

  _abort_current: =>
    activity_id = @current.activity_id
    handle = @current.parked_handle

    @_finish activity_id
    @aborted[activity_id] = true

    if handle
      dispatch.launch -> dispatch.resume handle

    if @current and activity_id == @current.activity_id
      -- hard clear, polite attempt didn't work
      @running[#@running] = nil

  abort_all: =>
    while @current
      @_abort_current!

  _cursor_to_end: =>
    @command_widget.cursor\eof!

  _adjust_height_rows: =>
    width_cols = @command_widget.width_cols
    return unless width_cols > 0

    max_height = math.floor howl.app.window.allocated_height * 0.5

    num_lines = #@command_widget.buffer.lines
    height_rows = math.ceil @command_widget.buffer.lines[num_lines].text.ulen / @command_widget.width_cols
    height_rows = math.max 1, height_rows
    @command_widget.height_rows = height_rows

    while @command_widget.height > max_height and height_rows > 1
      height_rows -= 1
      @command_widget.height_rows = height_rows

  record_history: =>
    return if @current.evade_history or @history_recorded
    command_line = @_capture_command_line!

    for frame in *@running
      if frame.saved_command_line
        command_line = frame.saved_command_line .. command_line

    unless @_command_history[1] == command_line or command_line\find '\n' or command_line\find '\r'
      table.insert @_command_history, 1, command_line
    @history_recorded = true

  _capture_command_line: (end_pos)=>
      buf = @command_widget.buffer
      chunk = buf\chunk 1, (end_pos or #buf)
      return StyledText chunk.text, chunk.styles

  to_gobject: => @bin

  _initialize: =>
    @box = Gtk.Box Gtk.ORIENTATION_VERTICAL
    border_box = Gtk.EventBox {
      Gtk.Alignment {
        top_padding: 1,
        left_padding: 1,
        right_padding: 3,
        bottom_padding: 3,
        @box
      }
    }
    theme.register_background_widget border_box
    @bin\add border_box

    @command_widget = TextWidget
      top_padding: 3
      left_padding: 3
      bottom_padding: 2
      bottom_border: 1
      top_border: 1
      line_wrapping: 'char'
      on_keypress: (event) ->
        result = true
        if not @handle_keypress(event)
          result = false
        @post_keypress!
        return result
      on_changed: ->
        @on_update!
      on_focus_lost: ->
        @command_widget\focus! if @showing
      on_map: ->
        @_adjust_height_rows!

    @command_widget.height_rows = 1

    @box\pack_end @command_widget\to_gobject!, false, 0, 0

    @notification_widget = NotificationWidget!
    @box\pack_end @notification_widget\to_gobject!, false, 0, 0

    @header = IndicatorBar 'header', 3
    @indic_title = @header\add 'left', 'title'
    @box\pack_start @header\to_gobject!, false, 0, 0

  @property width_cols:
    get: => @command_widget.width_cols

  @property _activity:
    get: => @current and @current.activity

  @property _widgets:
    get: => @current and @current.command_line_widgets

  @property _left_stop:
    get: => @current and @current.command_line_left_stop

  @property _prompt_end:
    get: => @current and @_left_stop + @current.command_line_prompt_len

  @property _updating:
    get: => @current and @current.command_line_updating
    set: (value) =>
      return unless @current
      @current.command_line_updating = value

  @property title:
    get: => @current and @current.command_line_title
    set: (text) =>
      if not @current
        error 'Cannot set title - no running activity', 2

      @current.command_line_title = text if @current
      if text == nil or text.is_empty
        @header\to_gobject!\hide!
      else
        @header\to_gobject!\show!
        @indic_title.label = tostring text

  @property prompt:
    get: => @current and @command_widget.text\usub @_left_stop, @_prompt_end - 1
    set: (prompt='') =>
      if not @current
        error 'Cannot set prompt - no running activity', 2

      if @_left_stop <= @_prompt_end
        @command_widget\delete @_left_stop, @_prompt_end - 1

      @current.command_line_prompt = prompt
      @current.command_line_prompt_len = prompt.ulen

      if prompt
        @command_widget\insert prompt, @_left_stop, 'prompt'
        @\_cursor_to_end!


  @property text:
    get: => @current and @command_widget.text\usub @_prompt_end
    set: (text) =>
      if not @current
        error 'Cannot set text - no running activity', 2

      @clear!
      @write text

  notify: (text, style='info') =>
    if @notification_widget
      @notification_widget\notify style, text
      @notification_widget\show!
    else
      io.stderr\write text

  clear_notification: =>
    @notification_widget\hide! if @notification_widget

  clear: =>
    @command_widget\delete @_prompt_end, @command_widget.text.ulen
    @\_cursor_to_end!

  clear_all: =>
    @current.saved_command_line = @_capture_command_line @_left_stop - 1
    @command_widget\delete 1, @_left_stop - 1
    @current.command_line_left_stop = 1

  write: (text) =>
    @command_widget\append text
    @\_cursor_to_end!
    @\on_update!

  write_spillover: (text) =>
    -- spillover is saved text written to whichever activity is invoked next
    if @spillover
      @spillover = @spillover .. text
    else
      @spillover = text

  pop_spillover: =>
    spillover = @spillover
    @spillover = nil
    return spillover or ''

  post_keypress: =>
    @enforce_left_pos!

  on_update: =>
    -- only call on_update() after run() ends and before finish() begins
    return if not @current or @current.state != 'running'
    if @_activity and @_activity.on_update and not @_updating
      -- avoid recursive calls
      @_updating = true
      ok, err = pcall ->
        @_activity\on_update @text
      @_updating = false
      if not ok
        error err

    @_adjust_height_rows!

  enforce_left_pos: =>
    -- don't allow cursor to go left into prompt
    return if not @current
    left_pos = @_prompt_end or 1
    if @command_widget.cursor.pos < left_pos
      @command_widget.cursor.pos = left_pos

  handle_keypress: (event) =>
    -- keymaps checked in order:
    --   @preemptive_keymap - keys that cannot be remapped by activities
    --   @_activity.keymap
    --   widget.keymap for widget in @_widgets
    --   @keymap
    @clear_notification!
    @window.status\clear!

    return true if bindings.dispatch event, 'commandline', { @preemptive_keymap}, self

    activity = @_activity
    if activity and activity.keymap
      return true if bindings.dispatch event, 'commandline', { activity.keymap }, activity

    if @_widgets
      for _, widget in pairs @_widgets
        if widget.keymap
          return true if bindings.dispatch event, 'commandline', { widget.keymap }, widget

    return true if bindings.dispatch event, 'commandline', { @keymap }, self

    return false

  preemptive_keymap:
    ctrl_shift_backspace: => @abort_all!

  keymap:
    binding_for:
      ["cursor-home"]: => @command_widget.cursor.pos = @_prompt_end

      ["cursor-line-end"]: => @command_widget.cursor.pos = @_prompt_end + @text.ulen

      ["cursor-left"]: => @command_widget.cursor\left!

      ["cursor-right"]: => @command_widget.cursor\right!

      ["editor-delete-back"]: =>
        -- don't backspace into prompt
        return true if @command_widget.cursor.pos == @_prompt_end
        @command_widget\delete_back!
        @on_update!

      ["editor-paste"]: =>
        import clipboard from howl
        if clipboard.current
          @write clipboard.current.text

  add_widget: (name, widget) =>
    error('No widget provided', 2) if not widget

    @remove_widget name

    @box\pack_end widget\to_gobject!, false, 0, 0
    @_widgets[name] = widget

    widget\show!

  remove_widget: (name) =>
    widget = @_widgets[name]
    @box\remove widget\to_gobject! if widget
    @_widgets[name] = nil

  get_widget: (name) => @_widgets[name]

  show: =>
    return if @showing
    @last_focused = @window.focus if not @last_focused
    @window\remember_focus!

    @_initialize! if not @box

    @window.status\hide!
    @bin\show_all!
    @notification_widget\hide!

    with @command_widget
      \show!
      \focus!

    @title = @current and @current.command_line_title
    @showing = true

  hide: =>
    if @showing
      @bin\hide!
      @showing = false
      @window.status\show!
      @last_focused\grab_focus! if @last_focused
      @last_focused = nil

style.define_default 'prompt', 'keyword'

return CommandLine

