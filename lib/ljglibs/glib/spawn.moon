-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
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
  with_pipes: (opts = {}) ->
    error '.argv not specified in opts', 2 unless opts.argv

    argv = char_p_arr opts.argv
    pid = ffi_new 'GPid[1]'
    flags = core.parse_flags('G_SPAWN_', opts.flags)
    envp = get_envp opts.env

    stdin = opts.write_stdin and ffi_new('gint[1]') or nil
    stdout = opts.read_stdout and ffi_new('gint[1]') or nil
    stderr = opts.read_stderr and ffi_new('gint[1]') or nil

    catch_error C.g_spawn_async_with_pipes,
      opts.working_directory,
      argv, envp, flags,
      nil, nil,
      pid,
      stdin, stdout, stderr

    pid = tonumber pid[0]

    destructor = ffi_gc ffi_new('struct {}'), ->
      C.g_spawn_close_pid pid

    {
      :pid
      flags: flags
      stdin_pipe: stdin and stdin[0] or nil
      stdout_pipe: stdout and stdout[0] or nil
      stderr_pipe: stderr and stderr[0] or nil

      __destructor: destructor
    }
}

spawn[flag] = flags[v] for flag, v in pairs flags

spawn
