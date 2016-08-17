-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
import bindings, config, dispatch, interact, signal from howl
import Matcher from howl.util
import PropertyObject from howl.util.moon
import ActionBuffer, BufferPopup, highlight, markup, style, theme from howl.ui
{:TextWidget, :NotificationWidget, :IndicatorBar, :StyledText, :ContentBox} = howl.ui

append = table.insert

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
    @aborted = {}
    @next_run_queue = {}
    @_command_history = {}
    @sync_history!

  @property current: get: => @running[#@running]

  @property stack_depth: get: => #@running

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
          @close_popup!
          bindings.cancel_capture!
          if @spillover and not @spillover.is_empty
            -- allow editor to resize for correct focusing behavior
            howl.timer.asap ->
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

    append @running, activity_frame

    @_initialize! if not @box

    with @current
      .command_line_left_stop = @command_widget.text.ulen + 1
      .command_line_widgets = { }
      .command_line_keymaps = { }
      .command_line_help = { keys: { } }
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
    append @next_run_queue, f

  switch_to: (new_command) =>
    captured_text = @text
    howl.timer.asap ->
      @abort_all!
      howl.command.run new_command .. ' ' .. captured_text

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

    if #results > 0 and not @current.evade_history and not @history_recorded
      @record_history!

    @clear!
    @prompt = nil

    for name, _ in pairs @_widgets
      @remove_widget name

    if @current.saved_command_line
      @command_widget\insert @current.saved_command_line, 1
      @current.saved_command_line = nil

    if @current.saved_widgets
      for widget in *@_all_widgets
        if @current.saved_widgets[widget]
          widget\show!

    @running[#@running] = nil

    if @stack_depth > 0
      @title = @title
      @close_popup!
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

  disable_auto_record_history: =>
    @current.evade_history = true

  record_history: =>
    @history_recorded = true
    command_line = @_capture_command_line!

    for frame in *@running
      if frame.saved_command_line
        command_line = frame.saved_command_line .. command_line

    current_history = @get_history @running[1].name
    last_cmd = current_history[1]


    unless last_cmd == command_line or command_line\find '\n' or command_line\find '\r'
      name = @running[1].name
      append @_command_history, 1, {:name, cmd: command_line, timestamp: howl.sys.time!}

    @sync_history!

  sync_history: =>
    return unless howl.app.settings
    saved_history = howl.app.settings\load_system 'command_line_history'
    saved_history or= {}

    history = {}
    for item in *@_command_history
      history[item.timestamp] = item

    for item in *saved_history
      continue if history[item.timestamp]
      item.cmd = StyledText item.cmd.text, item.cmd.styles
      history[item.timestamp] = item

    merged_history = [item for _, item in pairs history]
    table.sort merged_history, (a, b) -> a.timestamp > b.timestamp
    deduped_history = {}
    commands = {}
    limit = config.command_history_limit
    count = 0
    for item in *merged_history
      continue if commands[item.cmd.text]
      append deduped_history, item
      commands[item.cmd.text] = true
      count += 1
      break if count >= limit

    howl.app.settings\save_system 'command_line_history', deduped_history
    @_command_history = deduped_history

  _capture_command_line: (end_pos) =>
      buf = @command_widget.buffer
      chunk = buf\chunk 1, (end_pos or #buf)
      return StyledText chunk.text, chunk.styles

  get_history: (activity_name) =>
    return [item.cmd for item in *@_command_history when activity_name == item.name]

  to_gobject: => @bin

  _initialize: =>
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
        @on_update!
      on_focus_lost: ->
        @close_popup!
        @command_widget\focus! if @showing

    @command_widget.visible_rows = 1
    @box\pack_end @command_widget\to_gobject!, false, 0, 0

    @help_buffer = ActionBuffer!

    @notification_widget = NotificationWidget!
    @box\pack_end @notification_widget\to_gobject!, false, 0, 0

    @header = IndicatorBar 'header'
    @indic_title = @header\add 'left', 'title'
    @box.margin_left = 2
    @box.margin_top = 2
    c_box = ContentBox 'command_line', @box, {
      header: @header\to_gobject!
    }
    @bin\add c_box\to_gobject!

  @property width_cols:
    get: => @command_widget.width_cols

  @property _activity:
    get: => @current and @current.activity

  @property _widgets:
    get: => @current and @current.command_line_widgets

  @property _help:
    get: => @current and @current.command_line_help

  @property _keymaps:
    get: => @current and @current.command_line_keymaps

  @property _all_widgets:
    get: =>
      widgets = {}
      for frame in *@running
        for _, widget in pairs frame.command_line_widgets
          append widgets, widget
      return widgets

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

  refresh_help: =>
    buffer = @help_buffer
    buffer.text = ''

    help_texts, help_keys = @get_help!
    for def in *help_texts
      if def.heading
        buffer\append markup.howl "<h1>#{def.heading}</>\n"
      if def.text
        buffer\append def.text
        buffer\append '\n'
      buffer\append '\n' if #help_keys > 0

    if #help_keys > 0
      buffer\append markup.howl "<h1>Keys</>\n"
      keys = {}
      for def in *help_keys
        append keys, {markup.howl("<keystroke>#{def.key}</>"), def.action}
      buffer\append howl.ui.StyledText.for_table keys

  show_help: =>
    @refresh_help!
    popup = BufferPopup @help_buffer
    @show_popup popup

  close_popup: =>
    if @popup
      @popup\destroy!
      @popup = nil
      return true

  show_popup: (popup, options = {}) =>
    @close_popup!
    popup\show howl.app.window\to_gobject!, x:1, y:1
    popup\center!
    @popup = popup

  notify: (text, style='info') =>
    if #text == 0
      @clear_notification!
      return

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

    @current.saved_widgets = {}
    for widget in *@_all_widgets
      if widget.showing
        widget\hide!
        @current.saved_widgets[widget] = true

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
      @refresh_help!

  enforce_left_pos: =>
    -- don't allow cursor to go left into prompt
    return if not @current
    left_pos = @_prompt_end or 1
    if @command_widget.cursor.pos < left_pos
      @command_widget.cursor.pos = left_pos

  handle_keypress: (event) =>
    -- keymaps checked in order:
    --   @preemptive_keymap - keys that cannot be remapped by activities
    --   widget.keymap for widget in @_widgets
    --   @_activity.keymap
    --   command_line_keymaps for every running activity, newest to oldest
    --   @default_keymap
    @clear_notification!
    @window.status\clear!
    @close_popup! unless event.key_name == 'escape'

    return true if bindings.dispatch event, 'commandline', { @preemptive_keymap}, self

    if @_widgets
      for _, widget in pairs @_widgets
        if widget.keymap
          return true if bindings.dispatch event, 'commandline', { widget.keymap }, widget

    activity = @_activity
    if activity.keymap
      return true if bindings.dispatch event, 'commandline', { activity.keymap }, activity

    for i = @stack_depth, 1, -1
      frame = @running[i]
      for keymap in *frame.command_line_keymaps
        return true if bindings.dispatch event, 'commandline', { keymap }, frame.activity

    return true if bindings.dispatch event, 'commandline', { @default_keymap }, self

    return false

  preemptive_keymap:
    ctrl_shift_backspace: => @abort_all!
    escape: =>
      return false unless @close_popup!


  default_keymap:
    binding_for:
      ["cursor-home"]: => @command_widget.cursor.pos = @_prompt_end

      ["cursor-line-end"]: => @command_widget.cursor.pos = @_prompt_end + @text.ulen

      ["cursor-left"]: => @command_widget.cursor\left!

      ["cursor-right"]: => @command_widget.cursor\right!

      ["editor-delete-back"]: =>
        -- don't backspace into prompt
        return true if @command_widget.cursor.pos <= @_prompt_end
        range_start = @command_widget.selection\range!
        return if range_start and range_start < @_prompt_end
        @command_widget\delete_back!
        @on_update!

      ["editor-paste"]: =>
        import clipboard from howl
        if clipboard.current
          @write clipboard.current.text

    f1: => @show_help!

  add_widget: (name, widget) =>
    error('No widget provided', 2) if not widget

    @remove_widget name

    @box\pack_end widget\to_gobject!, false, 0, 0
    @_widgets[name] = widget

    widget\show!

  remove_widget: (name) =>
    widget = @_widgets[name]
    return unless widget
    widget\to_gobject!\destroy!
    @_widgets[name] = nil

  get_widget: (name) => @_widgets[name]

  add_keymap: (keymap) => append @current.command_line_keymaps, 1, keymap

  add_help: (help_defs) =>
    if #help_defs == 0
      help_defs = {help_defs}

    for def in *help_defs
      if def.key or def.key_for
        @_help.keys[def.key or def.key_for] = def
      elseif def.text or def.heading
        @_help.text = def

    @refresh_help!

  get_help: =>
    help_keys = {}
    help_texts = {}

    resolve_keys = (def) ->
      return def unless def.key_for
      keys = howl.bindings.keystrokes_for def.key_for, 'editor'
      if keys and keys[1]
        def = moon.copy def
        def.key = keys[1]
        return def

    for frame in *@running
      for _, def in pairs(frame.command_line_help.keys)
        def = resolve_keys def
        append(help_keys, def) if def
      if frame.command_line_help.text
        append help_texts, frame.command_line_help.text

    if @_activity.help
      help = @_activity.help
      help = help(@_activity) if type(help) == 'function'
      for def in *help
        if def.key or def.key_for
          def = resolve_keys def
          append(help_keys, def) if def
        elseif def.text
          append help_texts, def

    return help_texts, help_keys

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

  refresh: =>
    for frame in *@running
      frame.activity\refresh! if frame.activity.refresh

style.define_default 'prompt', 'keyword'
style.define_default 'keystroke', 'special'

config.define
  name: 'command_history_limit'
  description: 'The number of commands persisted in command line history'
  scope: 'global'
  type_of: 'number'
  default: 100

return CommandLine

