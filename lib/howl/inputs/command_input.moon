-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

glib = require 'ljglibs.glib'
import app from howl
import File from howl.io

get_cwd = ->
  buffer = app.editor and app.editor.buffer
  directory = buffer.file and buffer.file.parent or buffer.directory
  print "directory: #{directory}"
  directory or glib.get_current_dir!

input = {
  should_complete: -> false
  close_on_cancel: -> true

  complete: (text, readline) =>
    {}

  value_for: (text) =>
    @directory, text
}

howl.inputs.register {
  name: 'command',
  description: 'Returns a directory and a command to run within the directory',
  factory: (text, working_directory) ->
    directory = File(working_directory or get_cwd!)
    setmetatable {:directory}, __index: input
}
