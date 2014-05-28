-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

glib = require 'ljglibs.glib'
import app, sys from howl
import File from howl.io
import Matcher from howl.util
FileInput = howl.inputs.file
append = table.insert

command_matcher = nil

available_commands = ->
  commands = {}
  for path in sys.env.PATH\gmatch '[^:]+'
    dir = File path
    if dir.exists
      append commands, child.basename for child in *dir.children

  commands

match_command = (text) ->
  command_matcher = Matcher(available_commands!) unless command_matcher
  completion_options = {
    title: 'Command'
    list:
      highlight_matches_for: text
  }
  command_matcher(text), completion_options

sort_files = (files) ->
  table.sort files, (f1, f2) ->
    d1, d2 = f1.is_directory, f2.is_directory
    h1, h2 = f1.is_hidden, f2.is_hidden
    return false if h1 and not h2
    return true if h2 and not h1
    return true if d1 and not d2
    return false if d2 and not d1
    f1.path < f2.path

match_file = (directory, text) ->
  path = directory\join(text)

  if path.is_directory
    directory = path
    text = ''
  else
    text = path.basename
    directory = path.parent

  children = directory.children
  sort_files children
  names = [c.display_name for c in *children]
  matcher = Matcher names

  completion_options = {
    title: 'File'
    list:
      highlight_matches_for: text
      column_styles: (name, row, column) ->
        file = directory / name
        file.is_directory and 'keyword' or 'string'
  }
  matcher(text), completion_options

should_auto_match_file = (text) ->
  text\match('%s*%./') or text\match('%S%s+%./')

get_cwd = ->
  buffer = app.editor and app.editor.buffer
  directory = buffer.file and buffer.file.parent or buffer.directory
  directory or glib.get_current_dir!

external_command_input = {
  should_complete: (readline) => should_auto_match_file readline.text

  complete: (text, readline) =>
    parts = [p for p in text\gmatch '%S+']
    append parts, '' if text\ends_with ' '
    if should_auto_match_file(text) or #parts > 1
      return match_file @directory, parts[#parts]
    else
      return match_command text

  on_readline_available: (readline) =>
    text = readline.text
    @chdir(@directory, readline)
    readline.text = text

  on_completed: (value, readline) =>
    text = readline.text
    cd_dir = text\match '^%s*cd%s+(.+)%s*$'
    text = cd_dir if cd_dir
    path = @directory / text

    if path.is_directory
      @chdir path, readline
    else
      readline.text ..= ' '

    false

  go_back: (readline) =>
    parent = @directory.parent
    @chdir(parent, readline) if parent

  value_for: (text) =>
    @directory, text

  chdir: (directory, readline) =>
    @base_prompt = readline.prompt unless @base_prompt
    trailing = directory.path == File.separator and '' or File.separator
    readline.prompt = "[#{directory.short_path}#{trailing}] $ "
    @directory = directory
}

howl.inputs.register {
  name: 'external_command',
  description: 'Returns a directory and a command to run within the directory',
  factory: (text, working_directory) ->
    directory = File(working_directory or get_cwd!)
    setmetatable {:directory}, __index: external_command_input
}
