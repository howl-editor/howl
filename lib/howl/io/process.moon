-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
{:spawn, :shell} = require 'ljglibs.glib'
callbacks = require 'ljglibs.callbacks'
dispatch = howl.dispatch
{:InputStream, :OutputStream} = howl.io

C, ffi_cast = ffi.C, ffi.cast
append = table.insert
child_watch_callback = ffi.cast 'GChildWatchFunc', callbacks.void3

signals = {}

for s in *{
  'HUP', 'INT', 'QUIT', 'ILL', 'TRAP', 'ABRT', 'BUS', 'FPE',
  'KILL', 'USR1', 'SEGV', 'USR2', 'PIPE', 'ALRM', 'TERM',
  'STKFLT', 'CHLD', 'CONT', 'STOP', 'TSTP', 'TTIN', 'TTOU',
  'URG', 'XCPU', 'XFSZ', 'VTALRM', 'PROF', 'WINCH', 'POLL',
  'PWR', 'SYS'
}
  signals[s] = tonumber C["sig_#{s}"]

signal_name = (signal) ->
  for name, sig in pairs signals
    return name if sig == signal

  'Unknown'

get_argv = (v) ->
  t = type v

  if t == 'string'
    v = shell.parse_argv v
  elseif t != 'table'
    return nil

  v

launch = (argv, p_opts) ->
  flags = { 'SEARCH_PATH', 'DO_NOT_REAP_CHILD' }
  append flags, 'STDOUT_TO_DEV_NULL' unless p_opts.read_stdout
  append flags, 'STDERR_TO_DEV_NULL' unless p_opts.read_stderr

  opts = {
    write_stdin: p_opts.write_stdin
    read_stdout: p_opts.read_stdout
    read_stderr: p_opts.read_stderr
    working_directory: p_opts.working_directory
    env: p_opts.env

    :flags
    :argv
  }

  spawn.async_with_pipes opts

child_exited = (pid, status, process) ->
  process\_handle_finish ffi_cast('gint', status)

class Process
  new: (opts) =>
    @argv = get_argv opts.cmd
    error 'opts.cmd missing or invalid', 2 unless @argv
    @_process = launch @argv, opts
    @pid = @_process.pid
    @stdin = OutputStream(@_process.stdin_pipe) if @_process.stdin_pipe
    @stdout = InputStream(@_process.stdout_pipe) if @_process.stdout_pipe
    @stderr = InputStream(@_process.stderr_pipe) if @_process.stderr_pipe

    handle = callbacks.register child_exited, "process-watch-#{@_process.pid}", @
    C.g_child_watch_add ffi_cast('GPid', @_process.pid), child_watch_callback, callbacks.cast_arg(handle.id)

  wait: =>
    return if @exited
    @_exit = dispatch.park "process-wait-#{@_process.pid}"
    dispatch.wait(@_exit)

  send_signal: (signal) =>
    signal = signals[signal] if type(signal) == 'string'
    C.kill(@pid, signal)

  _handle_finish: (status) =>
    @exited = true
    @successful = false
    @exited_normally = C.process_exited_normally(status) != 0

    if @exited_normally
      @signalled = false
      @exit_status = tonumber C.process_exit_status(status)
      @successful = @exit_status == 0
    else
      @signalled = C.process_was_signalled(status) != 0
      if @signalled
        @signal = tonumber(C.process_get_term_sig(status))
        @signal_name = signal_name @signal

    if @_exit
      dispatch.resume(@_exit)
      @_exit = nil

jit.off Process.new

Process
