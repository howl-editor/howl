-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
{:spawn, :get_current_dir, :PRIORITY_LOW} = require 'ljglibs.glib'
callbacks = require 'ljglibs.callbacks'
dispatch = howl.dispatch
{:File, :InputStream, :OutputStream} = howl.io

C, ffi_cast = ffi.C, ffi.cast
append = table.insert
child_watch_callback = ffi.cast 'GChildWatchFunc', callbacks.void3

signals = {}

for s in *{
  'HUP', 'INT', 'QUIT', 'ILL', 'TRAP', 'ABRT', 'BUS', 'FPE',
  'KILL', 'USR1', 'SEGV', 'USR2', 'PIPE', 'ALRM', 'TERM',
  'CHLD', 'CONT', 'STOP', 'TSTP', 'TTIN', 'TTOU', 'URG',
  'XCPU', 'XFSZ', 'VTALRM', 'PROF', 'WINCH', 'SYS'
}
  signals[s] = tonumber C["sig_#{s}"]

win_signals = {}
win_signals[signals['KILL']] = 1
win_signals[signals['INT']] = 1

jit.off true, true

signal_name = (signal) ->
  for name, sig in pairs signals
    return name if sig == signal

  'Unknown'

shell_quote = (s) ->
  if s\find '%s'
    "'#{s}'"
  else
    s

default_shell = if jit.os == 'Windows'
  if howl.sys.env.MSYSCON
    -- Running under MSYS2.
    "#{howl.sys.env.WD}sh.exe"
  else
    "#{howl.sys.env.SYSTEMROOT}/System32/cmd.exe"
else
  '/bin/sh'

get_command = (v, shell = default_shell) ->
  t = type v

  if t == 'string'
    arg = if shell\find 'cmd'
      -- Likely cmd.exe.
      '/C'
    else
      '-c'
    return { shell, arg, v }, v
  elseif t != 'table'
    return nil

  v, table.concat([shell_quote(tostring s) for s in *v], ' ')

launch = (argv, p_opts) ->
  flags = { 'SEARCH_PATH', 'DO_NOT_REAP_CHILD' }
  append flags, 'STDOUT_TO_DEV_NULL' unless p_opts.read_stdout
  append flags, 'STDERR_TO_DEV_NULL' unless p_opts.read_stderr
  working_directory = p_opts.working_directory and tostring p_opts.working_directory

  opts = {
    write_stdin: p_opts.write_stdin
    read_stdout: p_opts.read_stdout
    read_stderr: p_opts.read_stderr
    working_directory: working_directory
    env: p_opts.env

    :flags
    :argv
  }

  spawn.async_with_pipes opts

child_exited = (pid, status, process) ->
  process\_handle_finish ffi_cast('gint', status)

pump_stream = (stream, handler, parking) ->
  local read_handler
  read_handler = (status, ret, err_code) ->
    if not status
      dispatch.resume_with_error parking, "#{ret} (#{err_code})"
    else
      handler ret
      if ret == nil
        stream\close!
        pcall dispatch.resume, parking
      else
        stream\read_async nil, read_handler

  stream\read_async nil, read_handler

class Process
  running: {}

  execute: (cmd, opts = {}) ->
    p_opts = {
      :cmd,
      working_directory: opts.working_directory,
      env: opts.env,
      shell: opts.shell,
      read_stdout: true,
      read_stderr: true,
      write_stdin: opts.stdin != nil and not opts.stdin.is_empty
    }
    p = Process p_opts
    if p_opts.write_stdin
      p.stdin\write opts.stdin
      p.stdin\close!

    stdout, stderr = p\pump!
    stdout, stderr, p

  new: (opts) =>
    @argv, @command_line = get_command opts.cmd, opts.shell
    error 'opts.cmd missing or invalid', 2 unless @argv
    @_process = launch @argv, opts
    @true_pid = @_process.true_pid
    @pid = @_process.pid
    @working_directory = File opts.working_directory or get_current_dir!
    @stdin = OutputStream(@_process.stdin_pipe) if @_process.stdin_pipe
    @stdout = InputStream(@_process.stdout_pipe) if @_process.stdout_pipe
    @stderr = InputStream(@_process.stderr_pipe, PRIORITY_LOW - 10) if @_process.stderr_pipe
    @stdout_done = nil
    @stderr_done = nil
    @exited = false

    @@running[@pid] = @

    @_exit_handle = callbacks.register child_exited, "process-watch-#{@pid}", @
    C.g_child_watch_add ffi_cast('GPid', @true_pid), child_watch_callback, callbacks.cast_arg(@_exit_handle.id)

  wait: =>
    return if @exited
    @_exit = dispatch.park "process-wait-#{@pid}"
    dispatch.wait @_exit

  send_signal: (signal) =>
    signal = signals[signal] if type(signal) == 'string'
    if jit.os == 'Windows'
      error "Signal #{signal} is not supported on Windows" unless win_signals[signal]
      -- On Bash, when a process exits due to a signal, it's exit code is
      -- 128+{signal code}. Since killing a process like that doesn't
      -- necessarily work on Windows, this emulates that exit code.
      C.TerminateProcess(@true_pid, 128+signal)
    else
      C.kill(@pid, signal)

  pump: (on_stdout, on_stderr) =>
    if on_stdout and not @stdout
      error 'Can not pump process out: .stdout not set', 2

    if on_stderr and not @stderr
      error 'Can not pump process error: .stderr not set', 2

    stdout = nil
    stderr = nil

    if not on_stdout and @stdout
      stdout = {}
      on_stdout = (out) -> stdout[#stdout + 1] = out

    if not on_stderr and @stderr
      stderr = {}
      on_stderr = (err) -> stderr[#stderr + 1] = err

    @stdout_done = on_stdout and dispatch.park "process-wait-stdout-#{@pid}"
    @stderr_done = on_stderr and dispatch.park "process-wait-stderr-#{@pid}"
    pump_stream(@stderr, on_stderr, @stderr_done, true) if on_stderr
    pump_stream(@stdout, on_stdout, @stdout_done) if on_stdout

    dispatch.wait(@stdout_done) if on_stdout
    @stdout_done = nil
    dispatch.wait(@stderr_done) if on_stderr
    @stderr_done = nil
    @wait!

    stdout = stdout and table.concat(stdout)
    stderr = stderr and table.concat(stderr)
    stdout, stderr

  _handle_finish: (status) =>
    callbacks.unregister @_exit_handle
    @@running[@pid] = nil
    @_exit_handle = nil
    @exited = true
    @successful = false
    @exited_normally = C.process_exited_normally(status) != 0

    if @exited_normally
      @signalled = false
      @exit_status = tonumber C.process_exit_status(status)
      @exit_status_string = "exited normally with code #{@exit_status}"
      @successful = @exit_status == 0
    else
      @signalled = C.process_was_signalled(status) != 0
      if @signalled
        @signal = tonumber(C.process_get_term_sig(status))
        @signal_name = signal_name @signal
        @exit_status_string = "killed by signal #{@signal} (#{@signal_name})"
      else
        @exit_status_string = "exited abnormally for unknown reasons"

    if @_exit
      dispatch.resume(@_exit)
      @_exit = nil

    -- On Windows, read_async may never call the callback, so the dispatchers
    -- need to be resumed here instead.
    if @stdout_done
      pcall dispatch.resume, @stdout_done
      @stdout_done = nil
    if @stderr_done
      pcall dispatch.resume, @stderr_done
      @stderr_done = nil
