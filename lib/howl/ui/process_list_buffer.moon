-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:app, :log, :mode, :signal, :sys, :timer} = howl
{:ActionBuffer, :StyledText} = howl.ui
{:Process} = howl.io
{:floor, :max, :min} = math

HEADER_LINES = 1

format_duration = (secs) ->
  secs = floor secs
  h, m, s = floor(secs / 3600), floor(secs / 60) % 60, secs % 60
  return string.format('%dh %02dm %02ds', h, m, s) if h > 0
  return string.format('%dm %02ds', m, s) if m > 0
  "#{s}s"

with_process = (f) -> (editor) ->
  process = editor.buffer\process_at editor.cursor.line
  if process
    f process
  else
    log.info 'No process on this line'

ProcessListMode = {
  default_config:
    line_wrapping: 'none'
    line_numbers: false
    edge_column: 0

  keymap: {
    editor: {
      s: with_process (process) ->
        log.info "Stopping #{process.title}"
        process\stop!

      K: with_process (process) ->
        log.info "Killing #{process.title}"
        process\send_signal 'KILL'
    }
  }
}

class ProcessListBuffer extends ActionBuffer
  new: =>
    super!
    @title = 'Processes'
    @mode = mode.by_name 'process-list'
    @read_only = true
    @_refresh = -> @refresh!
    signal.connect 'process-started', @_refresh
    signal.connect 'process-exited', @_refresh
    @refresh!

  process_at: (line_nr) =>
    @processes[line_nr - HEADER_LINES]

  refresh: (now = sys.time!) =>
    @processes = Process.long_lived!
    editor = app\editor_for_buffer @
    line, column = if editor then editor.cursor.line, editor.cursor.column

    @modify ->
      @text = ''
      if #@processes == 0
        @append 'No long-lived processes\n', 'comment'
      else
        rows = [{ p.pid, p.title, p.working_directory.short_path, format_duration(now - p.started_at) } for p in *@processes]
        @append StyledText.for_table rows, {
          { header: 'PID', align: 'right', style: 'number' }
          { header: 'Title', style: 'string' }
          { header: 'Directory', style: 'comment' }
          { header: 'Running for', align: 'right' }
        }
        @append '\ns: stop, K: kill\n', 'comment'

    if editor
      last = max 1, #@processes + HEADER_LINES
      editor.cursor\move_to line: min(max(line, HEADER_LINES + 1), last), :column

    @_schedule_tick!

  stop_updates: =>
    @closed = true
    @_cancel_tick!
    signal.disconnect 'process-started', @_refresh
    signal.disconnect 'process-exited', @_refresh

  -- keeps the running times current while there are processes listed
  _schedule_tick: =>
    if @closed or #@processes == 0
      @_cancel_tick!
    elseif not @_tick
      @_tick = timer.after_exactly 1, ->
        @_tick = nil
        @refresh!

  _cancel_tick: =>
    timer.cancel @_tick if @_tick
    @_tick = nil

  modify: (f) =>
    @read_only = false
    f!
    @read_only = true
    @modified = false

signal.connect 'buffer-closed', (params) ->
  {:buffer} = params
  buffer\stop_updates! if typeof(buffer) == 'ProcessListBuffer'

mode.register {
  name: 'process-list'
  create: -> ProcessListMode
}

ProcessListBuffer
