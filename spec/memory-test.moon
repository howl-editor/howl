-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Buffer, app, command, dispatch from howl
import BufferPopup from howl.ui
{:ceil} = math
ffi = require 'ffi'
C = ffi.C
append = table.insert

-- jit off, since that will consume memory of its own otherwise
-- which confuses things
jit.off!

ui_files = {}

local get_sys_mem, free_sys_mem

if howl.sys.info.os == 'linux'
  ffi = require 'ffi'
  ffi.cdef [[
    struct mallinfo {
               int arena;     /* Non-mmapped space allocated (bytes) */
               int ordblks;   /* Number of free chunks */
               int smblks;    /* Number of free fastbin blocks */
               int hblks;     /* Number of mmapped regions */
               int hblkhd;    /* Space allocated in mmapped regions (bytes) */
               int usmblks;   /* Maximum total allocated space (bytes) */
               int fsmblks;   /* Space in freed fastbin blocks (bytes) */
               int uordblks;  /* Total allocated space (bytes) */
               int fordblks;  /* Total free space (bytes) */
               int keepcost;  /* Top-most, releasable space (bytes) */
           };

    struct mallinfo mallinfo(void);
    int malloc_trim(size_t pad);
  ]]
  get_sys_mem = ->
    info = ffi.C.mallinfo!
    info.uordblks / 1024 -- for Kb

  free_sys_mem = ->
    ffi.C.malloc_trim(0)
else
  get_sys_mem = -> -1
  free_sys_mem = -> nil

process_events = ->
  jit.off true, true
  count = 0
  while count < 1000 and C.g_main_context_iteration(howl_main_ctx, false) != 0
    count += 1

wait_for = (seconds) ->
  parking = dispatch.park 'wait'
  howl.timer.after seconds, -> dispatch.resume parking
  dispatch.wait parking

collect = ->
  mem = collectgarbage('count')
  iterations = 10
  while true
    collectgarbage!
    used = collectgarbage('count')
    break if used >= mem and iterations <= 0
    mem = used
    iterations -= 1

  process_events!
  free_sys_mem!

used = ->
  ceil(collectgarbage 'count')

take = (nr, list) ->
  sel = {}
  for o in *list
    sel[#sel + 1] = o
    break if #sel == nr

  sel

setup_environment = ->
  ui_inventory = app.root_dir\join('lib', 'howl', 'ui').children
  ui_files = [f for f in *ui_inventory when f.extension == 'moon']
  base_inventory = app.root_dir\join('lib', 'howl').children

  nr_files = 0
  for f in *base_inventory
    if f.extension == 'moon'
      nr_files += 1
      app\open_file f
      break if nr_files == 10

  log.info "Opened #{nr_files} files"
  process_events!
  wait_for 0.5

do_for_each_open_buffer = (files, op) ->
  nr_open_buffers = #app.buffers
  buffers = {}

  for f in *files
    buffer = app\open_file f
    append buffers, buffer
    process_events!
    op buffer

  for b in *buffers
    app\close_buffer b

  assert #app.buffers == nr_open_buffers, "Nr of buffers mismatch (#{#app.buffers} != #{nr_open_buffers})"

say = (what, ...) ->
  msg = string.format what, ...
  log.info msg
  print msg
  process_events!

run_test = (title, units, count, f) ->
  units = "#{units}%" if type(units) == 'number'
  val, unit = units\match '(%d+)(%S+)'
  if not (val and unit) and (unit == '%' or unit == 'Kb')
    error "Unknown unit specifier '#{units}'"

  val = tonumber val

  say "Testing '#{title}'.."
  f! -- warmup
  collect!
  baseline = used!
  sys_baseline = get_sys_mem!
  say "Testing '%s' (baseline %dKb, sys_baseline %dKb)..",
    title, baseline, sys_baseline

  for _ = 1, count
    f!

  collect!
  mem = used!
  diff = mem - baseline
  percentual = (diff / baseline) * 100

  sys_mem = get_sys_mem!
  sys_diff = sys_mem - sys_baseline
  percentual = (sys_diff / sys_baseline) * 100

  if diff > 0
    if (unit == '%' and percentual > val) or (unit == 'Kb' and diff > val)
      err = string.format "%s: %dKb -> %dKb (diff = %dKb, %.2f%%) > %s",
        title, baseline, mem, diff, percentual, units
      error err

  say "  => #{title}: OK (Lua %dKb -> %dKb, diff = %dKb, %.2f%%, Sys %dKb -> %dKb, diff: %dKb) < #{units}",
    baseline, mem, diff, percentual, sys_baseline, sys_mem, sys_diff

  process_events!
  wait_for 1

dispatches = ->
  run_test 'Dispatches', '5Kb', 500, ->
    handle = howl.dispatch.park!
    howl.timer.asap ->
      howl.dispatch.resume handle

    howl.dispatch.wait handle

buffer_editing = ->
  large_chunk = string.rep "12345689 ABCDEFGHIJKLMNOPQRSTUV åäö Σὲ γνωρίζω ἀπὸ τὴν κόψη", 10, "\n"
  chunk_len = large_chunk.ulen

  run_test 'Background buffer editing', '5Kb', 20, ->
    buf = howl.Buffer {}
    buf.collect_revisions = false
    -- append
    for _ = 1, 20
      buf\append large_chunk

    -- random delete
    for _ = 1, 10
      pos = math.random #buf - chunk_len / 2
      buf\delete pos, pos + chunk_len / 2

    -- random insert
    for _ = 1, 10
      pos = math.random #buf
      buf\insert large_chunk, pos

visible_buffer_editing = ->
  large_chunk = string.rep "12345689 ABCDEFGHIJKLMNOPQRSTUV åäö Σὲ γνωρίζω ἀπὸ τὴν κόψη", 10, "\n"
  chunk_len = large_chunk.ulen

  run_test 'Visible buffer editing', '5Kb', 20, ->
    buf = howl.Buffer {}
    howl.app\add_buffer buf
    editor = howl.app.editor
    process_events!

    -- append
    for _ = 1, 20
      buf\append large_chunk
      process_events!

    -- random delete
    for _ = 1, 10
      pos = math.random #buf - chunk_len / 2
      editor.cursor.pos = pos
      buf\delete pos, pos + chunk_len / 2
      process_events!

    -- random insert
    for _ = 1, 10
      pos = math.random #buf
      editor.cursor.pos = pos
      buf\insert large_chunk, pos
      process_events!

    howl.app\close_buffer buf, true

switch_buffers = ->
  run_test 'Buffer switching', '10Kb', 30, ->
    for b in *app.buffers
      app.editor.buffer = b
      process_events!

split_views = ->
  run_test 'View splitting', '30Kb', 30, ->
    howl.app\new_editor placement: 'right_of'
    process_events!
    howl.app\new_editor placement: 'left_of'
    process_events!
    howl.app\new_editor placement: 'below'
    process_events!
    howl.app\new_editor placement: 'above'
    process_events!

    while #app.window.views > 1
      command.view_close!

show_popups = ->
  editor = howl.app.editor

  run_test 'Popup display', '10Kb', 30, ->
    buf = Buffer!
    buf.text = "Hello popup #{math.random! * 100}"
    popup = BufferPopup buf
    editor\show_popup popup
    process_events!
    editor\remove_popup!
    process_events!

open_and_close_buffers = ->
  run_test 'Open & close buffers', '10Kb', 30, ->
    do_for_each_open_buffer take(5, ui_files), -> nil

buffer_navigation = ->
  -- select some larger files that allow for scrolling
  big_files = {}
  for f in *ui_files
    if f.size > 1024 * 7
      big_files[#big_files + 1] = f
      break if #big_files == 1

  run_test 'Paging buffers', '10Kb', 50, ->
    do_for_each_open_buffer big_files, (b) ->
      cursor = app.editor.cursor
      command.cursor_start!
      process_events!
      while not cursor.at_end_of_file
        command.cursor_page_down!
        process_events!

run_interactive_command = (cmd, f) ->
  howl.timer.after 0.2, ->
    cmd_line = app.window.command_line
    view = cmd_line.command_widget.view

    view_ctrl = (action, ...) ->
      view[action] view, ...
      process_events!
      os.execute('sleep 0.1')

    f view_ctrl
    cmd_line\abort_all!

  command.run cmd

command_line_invocation = ->
  command.register
    name: 'insta-close'
    description: 'I. will. close. you.'
    input: ->
      process_events!
      app.window.command_line\abort_all!
      process_events!
    handler: -> error 'foo'

  run_test 'Command line open and close', '10Kb', 5, ->
    command.run 'insta-close'
  -- process_events!
  -- cmd_line\abort_all!
  -- process_events!

command_line_project_open = ->
  letters = [l for l in ('abcdefghijklmnopqrstuwvxyz')\gmatch '%w']
  run_test 'Interactive command: Project open', '10Kb', 5, ->
    run_interactive_command 'project-open', (view) ->
      for l in *letters
        view 'insert', l
        view 'delete_back'

command_line_switch_buffer = ->
  run_test 'Interactive command: Switch buffer', '30Kb', 10, ->
    run_interactive_command 'switch-buffer', (view) ->
      view 'insert', 'a'
      view 'insert', 'a'
      view 'delete_back'

run_commands = ->
  run_test 'Run external processes', '5Kb', 30, ->
    howl.io.Process.execute 'sleep 0.1 && cat README.md', working_directory: app.root_dir
    p = howl.io.Process cmd: 'echo pump me!', read_stdout: true
    p\pump -> nil

howl.signal.connect 'app-ready', ->
  unless get_sys_mem
    print [[
      **********************************************
      * System memory check is not available,
      * test will be run checking only Lua memory
      **********************************************
    ]]
  log.info 'Setting up test environment..'
  howl.config.preview_files = false
  setup_environment!

  status, err = pcall ->

    -- for i = 1, 10
      -- open_and_close_buffers!
      -- command_line_project_open!

    dispatches!
    buffer_editing!
    visible_buffer_editing!
    switch_buffers!
    split_views!
    show_popups!
    open_and_close_buffers!
    run_commands!
    buffer_navigation!
    command_line_invocation!
    command_line_switch_buffer!
    command_line_project_open!

  if not status
    log.info "FAILED: #{err}"
    wait_for 0.5
    print "FAILED: #{err}"
    os.exit(false)

  command.quit_without_save!

app.args = {app.args[1], '/no-such-dir/no-such-file'}
app\run!
