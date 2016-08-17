-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:Project, :app} = howl
{:sandbox} = howl.util
append = table.insert

project_lint_config = (root) ->
  for p in *{'lint_config.moon', 'lint_config.lua'}
    config = root\join(p)
    return config if config.exists

load_lint_whitelist = (root, config, for_file, lint) ->
  cfg, err = loadfile config
  unless cfg
    log.error "Failed to load lint config from '#{config}': #{err}"
    return lint.default_whitelist

  s_box = sandbox no_globals: true
  wl = s_box -> cfg!.whitelist_globals
  return lint.default_whitelist unless wl

  whitelist = setmetatable {}, __index: lint.default_whitelist
  rel_path = for_file\relative_to_parent root
  for pattern, list in pairs wl
    if rel_path\match(pattern)
      for symbol in *list
        whitelist[symbol] = true

  whitelist

load_project_lint_whitelist = (root, for_file, lint) ->
  lint_config = project_lint_config root
  return lint.default_whitelist unless lint_config
  load_lint_whitelist root, lint_config, for_file, lint

(buffer) ->
  lint = require "moonscript.cmd.lint"
  lint_whitelist = lint.default_whitelist

  if buffer.file
    project = Project.for_file buffer.file
    if project
      lint_whitelist = load_project_lint_whitelist project.root, buffer.file, lint
    elseif buffer.file\is_below(app.settings.dir)
      howl_lint_config = app.root_dir\join('lint_config.moon')
      lint_whitelist = load_lint_whitelist app.settings.dir, howl_lint_config, buffer.file, lint

  status, res, err = pcall lint.lint_code, buffer.text, buffer.title, lint_whitelist
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
  for nr, message in res\gmatch 'line (%d+): ([^\n\r]+)'
    inspection = {
      line: tonumber(nr)
      type: 'warning'
      :message
    }
    symbols = [s for s in message\gmatch "`([^`]+)`"]
    if #symbols == 1
      inspection.search = symbols[1]

    append inspections, inspection

  inspections
