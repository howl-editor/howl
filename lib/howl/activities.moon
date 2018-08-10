-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:config, :timer} = howl
{:Activity} = howl.ui
{:get_monotonic_time} = require 'ljglibs.glib'
append = table.insert

activities = {}
timer_handle = nil
return_to_focus = nil
hooked = 0
hook_count = 0
last_visibility = 0

cancel = (activity) ->
  if activity.def.cancel
    if not activity.cancelled
      activity.widget.title.text ..= ' (Cancelling..)'
      activity.widget.shortcuts.text = ''

    activity.def.cancel!
    activity.cancelled = true
  else
    activity.widget.text = 'This operation cannot be cancelled'

new_widget = (activity) ->
  def = activity.def

  widget = Activity title: def.title, keymaps: {
    {
      ctrl_c: -> cancel activity
    },
    activity.def.keymap
  }

  howl.app.window\add_widget widget\to_gobject!

  widget

update = ->
  return unless #activities > 0

  timer_handle = timer.after 0.2, update

  for i, activity in ipairs activities
    focused = i == #activities

    unless activity.widget
      activity.widget = new_widget activity

    def = activity.def
    status = def.status!
    widget = activity.widget
    widget.text = status
    activity.widget.keep_focus = focused

    if focused
      if def.cancel
        widget.shortcuts.text = '(Ctrl-C to cancel)'
    else
      widget.shortcuts.text = ''

  -- what should we show? we can use up to half of the window height
  _, win_height = howl.app.window\get_size!
  available_height = win_height / 2
  used = 0

  for i = #activities, 1, -1
    activity = activities[i]
    alloc_height = math.max 50, activity.widget\to_gobject!.allocated_height
    used += alloc_height
    visible = used < available_height
    activity.widget.visible = visible

yield = ->
  howl.app\pump_mainloop!

ui_update_hook = ->
  hook_count += 1
  return unless hook_count % 1000 == 0
  yield!

run = (def, f) ->
  assert def.title, "Missing activity field 'title'"
  assert def.status, "Missing activity field 'status'"
  return f! unless howl.app.window

  -- start = get_monotonic_time!
  activity = :def
  append activities, activity

  ms_since_last_show = (get_monotonic_time!  - last_visibility) / 1000

  unless timer_handle
    interval = if ms_since_last_show < 200
      0.1
    elseif ms_since_last_show < 400
      0.3
    else
      config.activities_popup_delay / 1000
    timer_handle = timer.after_approximately interval, update
    return_to_focus = howl.app.window.focus

  if def.preempt and hooked == 0
    debug.sethook ui_update_hook, 'c'
    hooked += 1

  rets = table.pack(pcall f)
  activities = [a for a in *activities when a != activity]

  if activity.widget
    howl.app.window\remove_widget activity.widget\to_gobject!
    last_visibility = get_monotonic_time!

  if #activities == 0
    timer.cancel timer_handle
    timer_handle = nil
    if return_to_focus
      return_to_focus\grab_focus!

    return_to_focus = nil

  if def.preempt
    hooked -= 1
    if hooked == 0
      debug.sethook!
      hook_count = 0

  -- end_t = get_monotonic_time!
  -- print "end activity '#{def.title}' in #{(end_t - start) / 1000 / 1000}"

  status = rets[1]

  if not status
    log.error "Activity #{def.title} failed: '#{rets[2]}'"
    nil
  else
    table.unpack rets, 2, rets.n

run_process = (def, p) ->
  interrupted = false
  read = 0
  output = {}
  err_output = {}

  process_status = def.status or ->
    units = def.read_lines and 'lines' or 'bytes'
    "$ #{p.command_line}.. (#{read} #{units} read)"
    "$ #{p.command_line}.."

  cancel_process = ->
    if interrupted
      p\send_signal 'KILL'
    else
      p\send_signal 'INT'
      interrupted = true

  p_def = {
    title: def.title
    status: process_status
    cancel: cancel_process
  }

  on_output = (out) ->
    return unless out
    read += #out
    if def.on_output
      def.on_output out
    else
      if def.read_lines
        append output, l for l in *out
      else
        output[#output + 1] = out

  on_error = (out) ->
    return unless out
    if def.on_error
      def.on_error out
    else
      if def.read_lines
        append err_output, l for l in *out
      else
        err_output[#err_output + 1] = out

  run p_def, ->
    output_handler = if p.stdout then on_output else nil
    error_handler = if p.stderr then on_error else nil

    if def.read_lines
      p\pump_lines output_handler, error_handler
    else
      p\pump output_handler, error_handler

  unless def.read_lines
    output = table.concat output
    err_output = table.concat err_output

  output, err_output

howl.util.property_table {
  nr:
    get: -> #activities

  nr_visible:
    get: -> #[a for a in *activities when a.widget]

  :run
  :run_process
  :yield
}
