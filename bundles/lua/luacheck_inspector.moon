-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

append = table.insert

-- the luacheck code is unfortunately tainted by the assumption that it's
-- a command line tool, run from a particular directory. We leave the luacheck
-- code along as it is and instead we just allow providing the current directory
-- via this override mechanism here instead
local luacheck_current_dir

require('luacheck.fs').get_current_dir = ->
  luacheck_current_dir or require('ljglibs.glib').get_current_dir!

luacheck = require 'luacheck'
luacheck_config = require 'luacheck.config'

-- luacheck configs are in the same directory or in one of the parent ones
get_config = (buffer, file) ->
  if file
    path = buffer.config.luacheck_config_path
    dir = file.is_directory and file or file.parent
    while dir
      conf = dir\join path
      return conf if conf.exists
      dir = dir.parent

  nil

(buffer) ->
  file = buffer.file or buffer.directory
  config = luacheck_config.empty_config
  config_file = get_config buffer, file

  if config_file
    data = buffer.data.luacheck
    if data and data.config_etag == config_file.etag
      config = data.config
    else
      luacheck_current_dir = config_file.parent.path
      config, err = luacheck_config.load_config config_file.path
      if err
        log.error "luacheck: '#{err}'"
        return {}

      buffer.data.luacheck = :config, config_etag: config_file.etag

  options = if buffer.file
    luacheck_config.get_options(config, buffer.file.path)
  else
    luacheck_config.get_top_options(config)

  status, res = pcall luacheck.check_strings, {buffer.text}, {options}

  unless status
    return {{
      line: 1
      message: "Luacheck error at unknown location: #{res}"
      type: 'error'
    }}

  issues = res[1]

  inspections = {}

  for i in *issues
    inspection = {
      line: i.line
      type: 'warning'
      message: luacheck.get_message(i),
      byte_start_col: i.column,
      byte_end_col: i.end_column + 1,
      search: i.name
    }
    append inspections, inspection

  inspections

