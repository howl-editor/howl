-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

glib = require 'ljglibs.glib'
import app from howl
import File from howl.io
import Matcher from howl.util
import markup, style from howl.ui

append = table.insert

separator = File.separator

root_dir = (file) ->
  while file.parent
    file = file.parent

  file

home_dir = -> File glib.get_home_dir!

display_name = (file, base_directory) ->
  return ".#{separator}" if file == base_directory
  file.display_name

class FileInput
  new: (text, @directory_reader) =>
    @directory = File(File.expand_path text) if text and not text.is_blank

    unless @directory and @directory.exists and @directory.is_directory
      @directory = File glib.get_current_dir!

      if app.editor
        file = app.editor.buffer.file
        @directory = file.parent if file

  should_complete: => true

  on_readline_available: (readline) =>
    @_chdir(@directory, readline)

  complete: (text, readline) =>
    if text == separator
      @_chdir(root_dir(@directory), readline)
    else if text == "~#{separator}"
      @_chdir(home_dir!, readline)
    else if text[-1] == separator
      subdir = @directory / text
      if subdir.exists and subdir.is_directory
        @_chdir(subdir, readline)

    completion_options = {
      title: 'File'
      list:
        highlight_matches_for: readline.text
        column_styles: (name, row, column) ->
          file = @directory / name
          file.is_directory and 'keyword' or 'string'
    }

    return self.matcher(readline.text), completion_options

  on_completed: (value, readline) =>
    path = @directory / value
    if path.is_directory and path != @directory
      @_chdir path, readline
      return false

  go_back: (readline) =>
    parent = @directory.parent
    @_chdir(parent, readline) if parent

  value_for: (basename) => @directory / basename

  _chdir: (directory, readline) =>
    children = self.directory_reader directory

    table.sort children, (f1, f2) ->
      d1, d2 = f1.is_directory, f2.is_directory
      h1, h2 = f1.is_hidden, f2.is_hidden
      return false if h1 and not h2
      return true if h2 and not h1
      return true if d1 and not d2
      return false if d2 and not d1
      f1.path < f2.path

    names = [display_name(c, directory) for c in *children]
    @matcher = Matcher names
    @directory = directory

    @base_prompt = readline.prompt unless @base_prompt
    basename = directory.short_path
    basename ..= separator if not basename\ends_with separator
    prompt = markup.howl "<prompt>#{@base_prompt}</><directory>#{basename}</>"
    readline.prompt = prompt

style.define_default 'directory', 'key'

howl.inputs.register {
  name: 'file',
  description: 'Returns a File instance',
  factory: (text) -> FileInput text, (directory) -> directory.children
}

howl.inputs.register {
  name: 'directory',
  description: 'Returns a File instance for a directory'
  factory: (text) -> FileInput text, (directory) ->
    kids = [c for c in *directory.children when c.is_directory]
    append kids, directory\join '.'
    kids
}
