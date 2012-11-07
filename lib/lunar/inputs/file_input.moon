import GLib from lgi
import File from lunar.fs
import Matcher from lunar.util

separator = File.separator

display_name = (file) ->
  name = file.basename
  name ..= separator if file.is_directory
  name

class FileInput
  new: =>
    @directory = File GLib.get_current_dir!

    if editor
      file = editor.buffer.file
      @directory = file.parent if file

  should_complete: => true

  complete: (text, readline) =>
    @_chdir(@directory, readline) unless @matcher

    completion_options = list: column_styles: (name, row, column) ->
      file = @directory / name
      file.is_directory and 'keyword' or 'string'

    return self.matcher(text), completion_options

  on_completed: (value) =>
    path = @directory / value
    if path.is_directory
      @_chdir path
      return false

  go_back: (readline) =>
    parent = @directory.parent
    @_chdir(parent, readline) if parent

  value_for: (basename) => @directory / basename

  _chdir: (directory, readline) =>
    children = directory.children

    table.sort children, (f1, f2) ->
      d1, d2 = f1.is_directory, f2.is_directory
      h1, h2 = f1.is_hidden, f2.is_hidden
      return false if h1 and not h2
      return true if h2 and not h1
      return true if d1 and not d2
      return false if d2 and not d1
      f1.path < f2.path

    names = [display_name c for c in *children]
    @matcher = Matcher names
    @directory = directory
    @base_prompt = readline.prompt .. readline.text unless @base_prompt
    prompt = @base_prompt .. tostring directory
    prompt ..= separator if not prompt\match separator .. '$'
    readline.prompt = prompt

lunar.inputs.register 'file', FileInput
return FileInput
