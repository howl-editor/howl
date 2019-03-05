import log, signal from howl
import ActionBuffer from howl.ui

append = table.insert

class JournalBuffer extends ActionBuffer
  new: =>
    super!

    @read_only = true
    @title = 'Howl Journal'
    @entry_sizes = {}

    @_appended = self\append_entry
    @_trimmed = self\trim

    signal.connect 'log-entry-appended', @_appended
    signal.connect 'log-trimmed', @_trimmed

    for entry in *log.entries
      @append_entry entry

  modify: (f) =>
    @read_only = false
    f!
    @read_only = true
    @modified = false

  append_entry: (entry) =>
    level = entry.level
    message = entry.message .. '\n'
    append @entry_sizes, message\count '\n'

    @modify ->
      editor = howl.app.editor
      at_end_of_file = editor and editor.cursor.at_end_of_file
      level = 'error' if level == 'traceback'
      @append message, level
      editor.cursor\eof! if at_end_of_file

    if howl.app.editor and howl.app.editor.buffer == @
      howl.app.editor.cursor\eof!

  trim: (options) =>
    size = options.size
    assert size <= #@entry_sizes

    nlines = 0
    to_remove = #@entry_sizes - size
    for _=1,to_remove
      nlines += table.remove @entry_sizes, 1

    @modify ->
      @lines\delete 1, nlines

signal.connect 'buffer-closed', (params) ->
  {:buffer} = params
  return if typeof(buffer) != 'JournalBuffer'

  signal.disconnect 'log-entry-appended', buffer._appended
  signal.disconnect 'log-trimmed', buffer._trimmed

return JournalBuffer
