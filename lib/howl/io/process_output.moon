-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
{:File} = howl.io

append = table.insert

line_p = r'(\\d+):(?:(\\d+):)?\\s*(.+)'

parse = (output, opts = {}) ->
  locations = {}
  base_dir = opts.directory or File glib.get_current_dir!
  lines = [l for l in output\gmatch('[^\n]+') ]
  for i = 1, #lines
    line = lines[i]
    nr, column, message = line\umatch line_p

    continue unless nr

    local file
    path = line\match '^([^:]+):%d+'
    path = nil if path and path\match('^%d+$')
    if path and path != '-'
      file = File.is_absolute(path) and File(path) or base_dir\join(path)

    tokens = [t for t in message\gmatch "[`'‘]([^'`‘]+)[`'‘]"]
    tokens = nil if #tokens == 0

    append locations, {
      :path
      :file,
      line_nr: tonumber(nr),
      column: tonumber(column),
      :message
      :tokens
    }

  locations

:parse
