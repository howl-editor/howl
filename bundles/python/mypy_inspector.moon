-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import File, Process from howl.io

append = table.insert

find_mypy_config = (buffer, dir) ->
  if dir
    path = buffer.config.mypy_config_path
    while dir
      conf = dir\join path
      return conf if conf.exists
      dir = dir.parent

(buffer) ->
  file = buffer.file or buffer.directory
  local config, dir
  if file
    dir = file.is_directory and file or file.parent
    config = find_mypy_config buffer, file

  cmd = {buffer.config.mypy_path, '--show-column-numbers', '--show-traceback',
         '-c', buffer.text}
  if config
    append cmd, '--config-file'
    append cmd, config.path

  opts = {}
  if dir
    opts.working_directory = dir

  stdout, stderr, _ = Process.execute cmd, opts
  inspections = {}

  for line in (stderr .. stdout)\gmatch '[^\n]+'
    path, lineno, colno, kind, message = line\match "([^:]+):(%d+):(%d+): ([^:]+): (.+)"
    if not (lineno and kind and message)
      append inspections,
        line: 1
        message: line
        type: 'warning'
      continue

    if message\find 'INTERNAL ERROR'
      return {{
        line: 1
        -- Internal error messages are always on stderr, tracebacks on stdout
        message: (stderr .. stdout)
        type: 'error'
      }}

    continue if path != '<string>'

    append inspections,
      line: tonumber lineno
      message: message
      type: kind
      byte_start_col: 1 + tonumber colno
      byte_end_col: 2 + tonumber colno

  inspections
