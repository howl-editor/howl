-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
{:File} = howl.io

append = table.insert

line_p = r'(\\d+):(?:(\\d+):)?\\s+(.+)'

parse = (output, opts = {}) ->
  locations = {}
  base_dir = opts.directory or File glib.get_current_dir!
  lines = [l for l in output\gmatch('[^\n]+') ]
  for i = 1, #lines
    line = lines[i]
    nr, column, message = line\umatch line_p

    continue unless nr

    file = line\match '^([^:]+):%d+'
    if file
      if file == '-' or file\match('^%d+$')
        file = nil
      else
        file = File.is_absolute(file) and File(file) or base_dir\join(file)

    tokens = [t for t in message\gmatch "[`'‘]([^'`‘]+)[`'‘]"]
    tokens = nil if #tokens == 0

    append locations, {
      :file,
      line: tonumber(nr),
      column: tonumber(column),
      :message
      :tokens
    }

  locations

:parse
