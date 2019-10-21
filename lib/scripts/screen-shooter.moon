-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, bindings, command, dispatch from howl
import theme from howl.ui
import File from howl.io
import get_cwd from howl.util.paths
Gdk = require 'ljglibs.gdk'

args = {...}

unless #args >= 1
  print 'Usage: screen-shooter <out-dir> [theme] [screenshot]'
  print '  theme - A specific theme, or "all" to generate a specific screenshot for all themes'
  print '  screenshot - A specific screenshot to generate'
  os.exit(1)

out_dir = File.tmpdir!
image_dir = File args[1]
project_dir = out_dir\join('howl')
examples_dir = out_dir\join('examples')
source_project = get_cwd!
howl.sys.env['HOME'] = out_dir.path
File.home_dir = out_dir

wait_for = (seconds) ->
  parking = dispatch.park 'wait'
  howl.timer.after seconds, -> dispatch.resume parking
  dispatch.wait parking

wait_a_bit = ->
  wait_for 0.2

press = (...) ->
  editor = app.editor
  buffer = editor.buffer
  mode = editor.mode_at_cursor
  maps = { buffer.keymap, mode and mode.keymap }

  command_line = app.window.command_panel.active_command_line
  for key in *{...}
    event = {key_name: key, character: key, key_code: 123}
    if command_line
      command_line\handle_keypress event
    else
      bindings.process event, 'editor', maps, editor

snapshot = (name, dir, opts) ->
  parking = dispatch.park 'shot'

  howl.timer.after (opts.wait_before or 0.5), ->
    pb = app.window\get_screenshot with_overlays: opts.with_overlays
    pb\save dir\join("#{name}.png").path, 'png', {}
    thumbnail = pb\scale_simple 314, 144, Gdk.INTERP_HYPER
    thumbnail\save dir\join("#{name}_tn.png").path, 'png', {}

    wait_for (opts.wait_after) or 0.5
    app.window.command_panel\cancel!
    dispatch.resume parking

  opts.run!
  dispatch.wait parking

  for buffer in *app.buffers
    app\close_buffer buffer, true

  for _ = 1, #app.window.views - 1
    command.view_close!

  log.info ''

open_files = (filepaths) ->
  for path in *filepaths
    app\open_file project_dir\join(path)
  wait_a_bit!  -- allow lexing

screenshots = {

  {
    name: 'file-open'
    ->
      command.run "open #{project_dir}/re"
  }

  {
    name: 'completion-types'
    with_overlays: true
    ->
      app\open_file examples_dir / 'test.rb'
      app.editor.cursor\move_to line: 4, column: 7
      command.editor_complete!
  }

  {
    name: 'project-open'
    ->
      app\open_file project_dir / 'lib/howl/application.moon'
      command.run 'project-open prsp'
  }

  {
    name: 'switch-buffer'
    ->
      open_files {
        'lib/howl/application.moon'
        'site/source/doc/index.haml'
        'lib/howl/command.moon'
      }

      command.run 'switch-buffer'
  }

  {
    name: 'buffer-structure'
    ->
      open_files { 'lib/howl/regex.moon' }
      app.editor.cursor.line = 17
      command.run 'buffer-structure'
  }

  {
    name: 'buffer-search-forward'
    ->
      open_files { 'lib/howl/ustring.moon' }
      app.editor.line_at_top = 137
      app.editor.cursor.line = 140
      command.run 'buffer-search-forward tex'
  }

  {
    name: 'buffer-grep'
    ->
      open_files { 'lib/howl/dispatch.moon' }
      dispatch.launch -> command.run 'buffer-grep resume'
      app.editor.line_at_top = 8
  }

  {
    name: 'buffer-replace'
    ->
      open_files { 'lib/howl/application.moon' }
      command.run 'buffer-replace /showing/'
  }

  {
    name: 'buffer-replace-regex'
    ->
      open_files { 'lib/howl/application.moon' }
      command.run 'buffer-replace-regex /\\w+\\s*=\\s*require(.+)/'
  }

  {
    name: 'buffer-modes'
    ->
      command.run 'buffer-mode'
  }

  {
    name: 'buffer-inspect'
    with_overlays: true
    ->
      app\open_file examples_dir / 'faulty.moon'
      app.editor.cursor\move_to line: 12
      command.run 'buffer-inspect'
      command.run 'cursor-goto-inspection'
  }

  {
    name: 'clipboard'
    ->
      howl.clipboard.clear!
      howl.clipboard.push 'http://howl.io/'
      howl.clipboard.push 'howl.clipboard.push "text"'
      howl.clipboard.push 'abc def'
      wait_a_bit!
      command.run 'editor-paste..'
  }

  {
    name: 'show-doc'
    with_overlays: true
    ->
      open_files { 'lib/howl/application.moon' }
      app.editor.cursor.pos = app.editor.buffer\find('table.sort') + 6
      app.editor.line_at_top = app.editor.cursor.line - 2
      command.show_doc_at_cursor!
  }

  {
    name: 'multi-views'
    ->
      open_files {
        'lib/howl/application.moon',
        'lib/howl/bundle.moon',
        'lib/howl/command.moon',
      }
      command.view_new_above!
      command.view_new_left_of!
  }

  {
    name: 'lots-of-views'
    wait_before: 2
    ->
      open_files {
        'lib/howl/application.moon',
        'lib/howl/bundle.moon',
        'lib/howl/command.moon',
        'lib/howl/regex.moon',
        'lib/howl/ustring.moon',
        'lib/howl/chunk.moon',
      }
      app.editor.line_at_top = 4

      command.view_new_right_of!
      app.editor.line_at_top = 10

      command.view_new_below!
      wait_a_bit!
      app.editor.line_at_top = 10

      command.view_new_right_of!
      wait_a_bit!
      app.editor.line_at_top = 10

      command.view_new_below!
      wait_a_bit!
      app.editor.line_at_top = 10

      wait_a_bit!
  }

  {
    name: 'exec-prompt'
    ->
      open_files { 'lib/howl/keymap.moon' }
      app.editor.line_at_top = 10
      command.run 'exec ls ./'
  }

  {
    name: 'whole-word-search'
    ->
      open_files { 'lib/howl/ustring.moon' }
      pos = app.editor.buffer\find 'pattern'
      line = app.editor.buffer.lines\at_pos pos
      app.editor.cursor.pos = pos
      app.editor.line_at_top = line.nr
      command.run 'buffer-search-word-forward'
  }

  {
    name: 'concurrent-commands'
    wait_before: 3
    wait_after: 1
    ->
      open_files { 'lib/howl/application.moon' }
      command.exec working_directory: project_dir, cmd: 'while true; do echo "foo"; sleep 1; done'
      command.exec working_directory: source_project, cmd: './bin/howl-spec'
      command.run 'switch-buffer'
  }

  {
    name: 'commands'
    ->
      dispatch.launch -> command.run ''
      press 'tab'
  }

  {
    name: 'configuration'
    ->
      command.run 'set'
  }

  {
    name: 'configuration-help'
    ->
      command.run 'set indent@global=4'
  }

  {
    name: 'command-line-help'
    with_overlays: true
    ->
      open_files {
        'lib/howl/application.moon'
        'site/source/doc/index.haml'
        'lib/howl/command.moon'
      }
      dispatch.launch -> command.run 'switch-buffer'
      app.window.command_panel.active_command_line\show_help!
  }

  {
    name: 'project-file-search'
    wait_before: 3
    wait_after: 1
    ->
      open_files { 'lib/howl/ustring.moon' }
      pos = app.editor.buffer\find 'append'
      line = app.editor.buffer.lines\at_pos pos
      app.editor.cursor.pos = pos
      app.editor.line_at_top = line.nr
      command.run 'project-file-search'
  }

  {
    name: 'project-file-search-list'
    wait_before: 3
    wait_after: 1
    with_overlays: true
    ->
      open_files { 'lib/howl/ustring.moon' }
      editor = app.editor
      cursor = editor.cursor
      pos = editor.buffer\find 'append'
      line = editor.buffer.lines\at_pos pos
      cursor.pos = pos
      editor.line_at_top = line.nr
      command.run 'project-file-search-list'
      press 'space'
      cursor\down!
      press 'space'
      cursor\down!
      press 'p'
  }

}

take_snapshots = (theme_name, to_dir, only) ->
  for _, def in ipairs screenshots
    if only and only != def.name
      continue

    if def.with_overlays and not only
      print "    = #{def.name} (external).."
      out, err, p = howl.io.Process.execute "#{howl.sys.env.SNAPSHOT_CMD} '#{image_dir}' '#{theme_name}' '#{def.name}'"
      if not p.successful
        print ">> External snapshot failed!"
        print out if #out > 0
        print err
        os.exit(p.exit_status)
    else
      print "    = #{def.name}.."
      snapshot "#{def.name}", to_dir, {
        wait_before: def.wait_before,
        wait_after: def.wait_after,
        with_overlays: def.with_overlays,
        run: def[1]
      }

get_theme = (name) ->
  for t_name in pairs theme.all
    if t_name\lower!\find name\lower!
      return t_name

setup_example_files = ->
  example_files = {
    'test.rb': 'class Foo

    attr_accessor :maardvark, :banana
    aa
  end
    '

    'faulty.moon': "mod = require 'mod'
{:insert} = table


first_func = (x) ->
  m = mod.foo 'x'

oops_shadow = (mod) ->
  mod\\gmatch '.*(%w+).*'

oops_shadow('mymod')
"
  }

  examples_dir\mkdir_p!
  for filename, contents in pairs example_files
    file = examples_dir / filename
    file.contents = contents

run = (theme_name, only) ->
  print "- Generating screenshots in '#{image_dir}' (tmp dir '#{out_dir}').."
  if only
    print "- Only generating #{only}"
  image_dir\mkdir_p! unless image_dir.is_directory

  print "- Setting up test project.."
  _, err, p = howl.io.Process.execute "git clone --shared '#{source_project}' '#{project_dir}'"
  unless p.successful
    error err

  print "- Setting up example files.."
  setup_example_files!

  local for_themes

  if theme_name and theme_name != 'all'
    for_themes = { get_theme theme_name }
    if #for_themes == 0
      available_themes = table.concat [n for n in pairs theme.all], '\n'
      print "Unknown theme '#{theme_name}'\nAvailable themes:\n\n#{available_themes}"
      os.exit(1)
  else
    for_themes = [n for n in pairs theme.all]

  print "- Taking screenshots.."
  app.window\resize 1048, 480
  for cur_theme in *for_themes
    howl.config.theme = cur_theme
    wait_a_bit!
    ss_dir = image_dir\join((cur_theme\lower!\gsub('%s', '-')))
    ss_dir\mkdir_p! unless ss_dir.exists
    print "  * #{cur_theme}.."
    take_snapshots cur_theme, ss_dir, only

howl.signal.connect 'app-ready', ->
  log.info ''
  status, ret = pcall run, args[2], args[3]
  out_dir\rm_r!
  unless status
    print ret
    os.exit(1)

  log.info 'All done!'
  os.exit(0)

howl.config.cursor_blink_interval = 0
howl.config.font_size = 10
app.args = {app.args[0]}
app\run!
