-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
--
-- Runs a scenario in a real Howl window, once per theme, saving the screenshots it
-- takes. Run through bin/howl-shot, which documents the options and the helpers
-- available to scenarios.

{:app, :command, :dispatch, :sys, :timer} = howl
{:theme} = howl.ui
{:File, :Process} = howl.io
{:max, :min} = math

append = table.insert

out_dir, theme_arg, scenario_path = ...
out_dir = File out_dir
width, height = (sys.env.HOWL_HEADLESS_SIZE or '1280x720')\match '^(%d+)x(%d+)$'

-- the shots of all themes, as { name:, theme:, path:, width: }
shots = {}
failures = 0
local current_theme

fail = (message) ->
  io.stderr\write "howl-shot: #{message}\n"
  failures += 1

wait = (seconds) ->
  handle = dispatch.park 'shot-wait'
  timer.after seconds, -> dispatch.resume handle
  dispatch.wait handle

-- polls until predicate returns a true value, which is returned
wait_for = (predicate, timeout = 5) ->
  deadline = sys.time! + timeout
  while true
    value = predicate!
    return value if value
    error "wait_for: nothing after #{timeout} seconds", 2 if sys.time! > deadline
    wait 0.05

-- opens path, relative to the Howl checkout unless absolute, with the cursor at the
-- start of the text `opts.at` or on line `opts.line`, near the top of the editor
open = (path, opts = {}) ->
  file = path\match('^/') and File(path) or app.root_dir / path
  buffer, editor = app\open_file file
  if opts.at
    pos = buffer\find opts.at
    error "open: '#{opts.at}' not found in #{path}", 2 unless pos
    editor.cursor.pos = pos
  elseif opts.line
    editor.cursor.line = opts.line

  editor.line_at_top = max 1, editor.cursor.line - 3
  -- allow lexing
  wait 0.2
  buffer, editor

-- runs a command in a coroutine of its own, so that interactions don't block
run = (cmd_text) ->
  dispatch.launch ->
    ok, err = pcall command.run, cmd_text
    fail "'#{cmd_text}' failed: #{err}" unless ok

wtype = (args) ->
  unless sys.env.HOWL_HEADLESS
    error 'sending keys needs the headless harness (sway and wtype)', 3
  _, err, p = Process.execute args
  error "wtype failed: #{err}", 3 unless p.successful
  wait 0.15

-- presses keys, given as X keysym names with optional modifiers: 'Down',
-- 'Return', 'ctrl+space', 'ctrl+shift+Left'
keys = (...) ->
  args = { 'wtype' }
  add = (...) -> append args, a for a in *{...}
  for key in *{...}
    modifiers = [p for p in key\gmatch '[^+]+']
    name = table.remove modifiers
    add '-M', m for m in *modifiers
    add '-k', name
    add '-m', m for m in *modifiers
  wtype args

type_text = (text) -> wtype { 'wtype', text }

bounds_of = (widget) ->
  x, y = widget\translate_coordinates app.window\to_gobject!, 0, 0
  { :x, :y, width: widget.allocated_width, height: widget.allocated_height }

crops = {
  popup: ->
    popovers = app.window\showing_popovers!
    error 'shot: no popup is showing', 4 if #popovers == 0
    x1, y1, x2, y2 = math.huge, math.huge, 0, 0
    for p in *popovers
      x1, y1 = min(x1, p.x), min(y1, p.y)
      x2 = max x2, p.x + p.popover.allocated_width
      y2 = max y2, p.y + p.popover.allocated_height
    { x: x1, y: y1, width: x2 - x1, height: y2 - y1 }

  editor: -> bounds_of app.editor\to_gobject!
  command_panel: -> bounds_of app.window.command_panel\to_gobject!
}

region_for = (crop, margin) ->
  return nil if crop == 'window'
  rect = if type(crop) == 'table'
    margin or= 0
    crop
  else
    margin or= 40
    get = crops[crop] or error "shot: unknown crop '#{crop}'", 3
    get!

  win = app.window\to_gobject!
  x, y = max(0, rect.x - margin), max(0, rect.y - margin)
  right = min win.allocated_width, rect.x + rect.width + margin
  bottom = min win.allocated_height, rect.y + rect.height + margin
  { :x, :y, width: right - x, height: bottom - y }

slug = (name) -> (name\lower!\gsub('%s+', '-'))

-- saves a screenshot of the window, including popups, or of the part given by
-- `opts.crop`: 'window', 'popup', 'editor', 'command_panel' or a rectangle
shot = (name, opts = {}) ->
  -- let what was just shown be laid out and drawn
  wait opts.settle or 0.3
  region = region_for opts.crop or 'window', opts.margin
  texture = app.window\get_screenshot with_overlays: true, :region
  dir = out_dir / slug(current_theme)
  dir\mkdir_p! unless dir.exists
  file = dir\join "#{name}.png"
  texture\save_to_png file.path
  append shots, { :name, theme: current_theme, path: file.path, width: texture.width }
  print file.path

helpers = {
  :open, :run, :wait, :wait_for, :keys, :type_text, :shot,
  :app, :command, config: howl.config
}

themes_for = (arg) ->
  all = [name for name in pairs theme.all]
  table.sort all
  -- the default rather than the current theme, which can be a saved setting
  return { howl.config.definitions.theme.default } if not arg or arg.is_blank
  return all if arg == 'all'
  names = {}
  for wanted in arg\gmatch '[^,]+'
    found = [name for name in *all when name\lower!\find(wanted\lower!, 1, true)]
    error "no theme matches '#{wanted}', available: #{table.concat all, ', '}" if #found == 0
    append names, n for n in *found
  names

-- leaves the window as it was for the next theme
clean_up = ->
  app.editor\remove_popup! if app.editor
  app.window.command_panel\cancel!
  app\close_buffer buffer, true for buffer in *app.buffers
  for _ = 1, #app.window.views - 1
    command.view_close!
    wait 0.2

  log.info ''

run_scenario = ->
  scenario, err = loadfile scenario_path
  error err unless scenario
  setfenv scenario, setmetatable(moon.copy(helpers), __index: _G)
  taken = #shots
  ok, s_err = xpcall scenario, debug.traceback
  fail "#{current_theme}: #{s_err}" unless ok
  fail "#{current_theme}: the scenario took no shot" if ok and #shots == taken

-- combines each shot's images for the themes into one, if ImageMagick is installed
montage = (themes) ->
  cmd = sys.find_executable('montage') and { 'montage' }
  cmd or= sys.find_executable('magick') and { 'magick', 'montage' }
  unless cmd
    io.stderr\write 'howl-shot: ImageMagick not found, no theme comparison made\n'
    return

  names = {}
  by_name = {}
  for s in *shots
    unless by_name[s.name]
      append names, s.name
      by_name[s.name] = {}
    append by_name[s.name], s

  for name in *names
    args = moon.copy cmd
    for s in *by_name[name]
      append args, a for a in *{ '-label', s.theme, s.path }

    columns = by_name[name][1].width > 1600 and 2 or 3
    file = out_dir\join "#{name}-themes.png"
    append args, a for a in *{ '-tile', "#{columns}x", '-geometry', '+8+8', '-pointsize', '20', file.path }
    _, err, p = Process.execute args
    if p.successful
      print file.path
    else
      fail "montage of '#{name}' failed: #{err}"

-- servers and other processes started by scenarios would outlive Howl
stop_processes = ->
  p\stop! for p in *Process.long_lived!
  for _ = 1, 20
    break if #Process.long_lived! == 0
    wait 0.1

main = ->
  app.window\set_default_size tonumber(width), tonumber(height)
  themes = themes_for theme_arg
  for name in *themes
    current_theme = name
    howl.config.theme = name
    wait 0.3
    run_scenario!
    clean_up!

  montage themes if #themes > 1 and #shots > 0
  stop_processes!

howl.signal.connect 'app-ready', ->
  log.info ''
  ok, err = pcall main
  fail err unless ok
  os.exit failures == 0 and 0 or 1

howl.config.cursor_blink_interval = 0
howl.config.font_size = 10
-- the script's arguments aren't files to open
app.args = { no_profile: app.args.no_profile }
app\run!
