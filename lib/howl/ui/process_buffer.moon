-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, mode from howl
import ActionBuffer from howl.ui
import terminal from howl.ui.markup
import File from howl.io
append = table.insert

command_activity = (process) ->
  {
    name: "process with pid #{process.pid}"
    is_running: -> not process.exited
    force_terminate: -> process\send_signal 'KILL'
  }

resolve_location = (base_directory, line) ->
  _, _, file, line = line\ufind r'([^\\s:]+):(\\d+)'
  if file
    file = File(file, base_directory)
    return { :file , line: tonumber line } if file.exists

  nil

goto_location = (location) ->
  _, editor = app\open_file location.file
  if editor
    editor.cursor.line = location.line
    editor.line_at_center = location.line

parse_output = (text) ->
  leading_bs, rest = text\match '^(\008*)(.*)$'
  #leading_bs, terminal(rest)

ProcessMode = {

  default_config:
    cursor_line_highlighted: false
    line_wrapping: 'character'

  keymap: {
    editor: {
      return: (editor) ->
        location = resolve_location editor.buffer.directory, editor.current_line
        if location
          goto_location(location)
        else
          log.error 'No file reference detected in the current line'

      ctrl_c: (editor) ->
        if editor.selection.empty
          process = editor.buffer.process
          if process.exited
            log.info "#{process.pid}: SIGINT is superflous - already terminated"
          else
            process\send_signal 'INT'
            log.info "Sent SIGINT to #{process.pid}"
       else
         editor.selection\copy!

      ctrl_backslash: (editor) ->
        process = editor.buffer.process
        if process.exited
          log.info "#{process.pid}: SIGKILL is superflous - already terminated"
        else
          process\send_signal 'KILL'
          log.info "Sent SIGKILL to #{process.pid}"
     }
  }

}

class ProcessBuffer extends ActionBuffer
  new: (@process) =>
    super!
    @read_only = true
    @activity = command_activity @process
    @directory = @process.working_directory
    @title = "$ #{@process.command_line} (running)"
    @mode = mode.by_name 'process'

    @append '[', 'operator'
    @append tostring(@process.working_directory.short_path), 'special'
    @append ']$', 'operator'
    @append " #{@process.command_line}\n"

  insert: (object, pos, style_name) =>
    @modify ->
      super object, pos, style_name

  append: (object, style_name) =>
    @modify ->
      editor = app\editor_for_buffer @
      at_end_of_file = editor and editor.cursor.at_end_of_file
      super object, style_name
      editor.cursor\eof! if at_end_of_file

  modify: (f) =>
    @read_only = false
    f!
    @read_only = true
    @modified = false

  pump: =>
    on_stdout = (read) ->
      if read and not @destroyed
        delete_back, output = parse_output read
        if delete_back > 0
          len = @length
          @modify ->  @delete len - (delete_back - 1), len

        @append output

    on_stderr = (read) ->
      @append(read, 'error') if read and not @destroyed

    @process\pump on_stdout, on_stderr
    @title = "$ #{@process.command_line} (done)"

    unless @destroyed
      @append '\n' unless @lines[#@lines].is_blank
      @append "=> Process terminated (#{@process.exit_status_string})", 'comment'

    editor = app\editor_for_buffer @
    editor.indicator.activity.visible = false if editor

    log_msg = "=> Command '#{@process.command_line}' terminated (#{@process.exit_status_string})"
    log[@process.exited_normally and 'info' or 'warn'] log_msg

    if #@lines == 2 -- no output
      app\close_buffer @

  destroy: =>
    @process\send_signal('KILL') unless @process.exited
    super!

howl.mode.register {
  name: 'process'
  create: -> ProcessMode
}

return ProcessBuffer
