-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
bit = require 'bit'
core = require 'ljglibs.core'
{ :catch_error, :char_p_arr } = require 'ljglibs.glib'

C, ffi_gc, ffi_new = ffi.C, ffi.gc, ffi.new

flags = {}

for flag in *{
  'DEFAULT',
  'LEAVE_DESCRIPTORS_OPEN',
  'DO_NOT_REAP_CHILD',
  'SEARCH_PATH',
  'STDOUT_TO_DEV_NULL',
  'STDERR_TO_DEV_NULL',
  'CHILD_INHERITS_STDIN',
  'FILE_AND_ARGV_ZERO',
  'SEARCH_PATH_FROM_ENVP',
}
  flags[flag] = C["G_SPAWN_#{flag}"]

get_envp = (env) ->
  return nil unless env
  char_p_arr ["#{k}=#{v}" for k,v in pairs env]

spawn = {
  async_with_pipes: (opts = {}) ->
    error '.argv not specified in opts', 2 unless opts.argv

    argv = char_p_arr opts.argv
    pid = ffi_new 'GPid[1]'
    spawn_flags = core.parse_flags('G_SPAWN_', opts.flags)
    if ffi.os == 'Windows'
      spawn_flags = bit.bor spawn_flags, flags['DO_NOT_REAP_CHILD']
    envp = get_envp opts.env

    stdin = opts.write_stdin and ffi_new('gint[1]') or nil
    stdout = opts.read_stdout and ffi_new('gint[1]') or nil
    stderr = opts.read_stderr and ffi_new('gint[1]') or nil

    -- XXX: This is a nasty hack!!
    -- On Windows, for reasons unknown, g_spawn_async_with_pipes will randomly
    -- fail with an EOF error (?). In order to work around that, on Windows,
    -- the spawn will be attempted three times first.

    limit = if jit.os == 'Windows'
      3
    else
      1

    for i=1,limit
      status, err = pcall catch_error, C.g_spawn_async_with_pipes,
        opts.working_directory,
        argv, envp, spawn_flags,
        nil, nil,
        pid,
        stdin, stdout, stderr

      if status
        break
      if jit.os == 'Windows' and err\match 'Failed to read from child pipe %(EOF%)'
        _G.print i, limit
        _G.io.flush!
        if i < limit
          -- Try sleeping for 1/10th second.
          C.g_usleep 100000
          continue
      error err

    true_pid = pid[0]
    local pid
    if ffi.os == 'Windows'
      pid = C.GetProcessId true_pid
    else
      true_pid = tonumber true_pid
      pid = true_pid

    caller_will_reap = bit.band(flags['DO_NOT_REAP_CHILD'], spawn_flags) != 0
    destructor = caller_will_reap and nil or ffi_gc ffi_new('struct {}'), ->
      C.g_spawn_close_pid true_pid

    {
      :true_pid
      :pid
      flags: spawn_flags
      stdin_pipe: stdin and stdin[0] or nil
      stdout_pipe: stdout and stdout[0] or nil
      stderr_pipe: stderr and stderr[0] or nil

      __destructor: destructor
    }
}

spawn[flag] = flags[v] for flag, v in pairs flags

spawn
