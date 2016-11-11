-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:Project, :app} = howl
{:sandbox} = howl.util
append = table.insert

moonpick = require "moonpick"
moonpick_config = require "moonpick.config"

project_lint_config = (root) ->
  for p in *{'lint_config.moon', 'lint_config.lua'}
    config = root\join(p)
    return config if config.exists

load_lint_config = (config_file, for_file) ->
  s_box = sandbox no_globals: true
  s_box ->
    moonpick_config.load_config_from config_file.path, for_file.path

(buffer) ->
  local lint_config
  file = buffer.file or buffer.directory

  if file
    config_file = nil

    if buffer.file\is_below(app.settings.dir)
      config_file = app.root_dir\join('lint_config.moon')
    else
      project = Project.for_file file
      if project
        config_file = project_lint_config project.root

    if config_file
      lint_config = load_lint_config config_file, file

  status, res, err = pcall moonpick.lint, buffer.text, lint_config

  unless status
    msg = res
    if type(msg) == 'table' and msg[1] == 'user-error'
      msg = msg[2]

    return {{
      line: 1
      message: "Moonscript error at unknown location: #{msg}"
      type: 'error'
    }}

  unless res
    if err and err\match '%[%d+%]'
      return {{
        line: tonumber(err\match('%[(%d+)%]'))
        message: "Syntax error: Failed to parse"
        type: 'error'
      }}
    return nil

  inspections = {}

  for i in *res
    inspection = {
      line: i.line
      type: 'warning'
      message: i.msg
    }
    symbols = [s for s in i.msg\gmatch "`([^`]+)`"]
    if #symbols == 1
      inspection.search = symbols[1]

    append inspections, inspection

  inspections
