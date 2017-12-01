{:spawn} = require 'ljglibs.glib'
{:UnixInputStream, :UnixOutputStream, :Win32InputStream, :Win32OutputStream} = require 'ljglibs.gio'
ffi = require 'ffi'

InputStream, OutputStream, shell = if jit.os == 'Windows'
  forward = (cls) -> (pipe) -> cls ffi.C._get_osfhandle pipe
  forward(Win32InputStream), forward(Win32OutputStream), "#{os.getenv 'WD'}/sh.exe"
else
  UnixInputStream, UnixOutputStream, 'sh'

describe 'spawn', ->

  describe 'async_with_pipes(opts)', ->
    it 'raises an error if the process could not be started', ->
      assert.raises 'no such file', -> spawn.async_with_pipes argv: { 'jguarlghladkjskjk!!' }

    it 'returns an object representing the spawned process', ->
      p = spawn.async_with_pipes {
        argv: {'id'},
        flags: { 'SEARCH_PATH', 'STDOUT_TO_DEV_NULL' }
      }

      assert.equals 'number', type(p.pid)
      collectgarbage!

    context '(when opts.read_stdout is given)', ->
      it 'sets .stdout_pipe for the process to a fd', ->
        p = spawn.async_with_pipes {
          argv: {'sh', '-c', 'echo foo'},
          read_stdout: true,
          flags: { 'SEARCH_PATH' }
        }
        assert.is_not_nil p.stdout_pipe
        stdout = InputStream p.stdout_pipe
        assert.equals 'foo\n', stdout\read_all!

    context '(when opts.write_stdin is given)', ->
      it 'sets .stdin_pipe for the process to a fd', ->
        p = spawn.async_with_pipes {
          argv: {'cat'},
          write_stdin: true,
          read_stdout: true,
          flags: { 'SEARCH_PATH' }
        }
        assert.is_not_nil p.stdin_pipe
        stdin = OutputStream p.stdin_pipe
        stdin\write_all 'give it back!'
        stdin\close!
        input_stream = InputStream p.stdout_pipe
        assert.equals 'give it back!', input_stream\read_all!

    context '(when opts.read_stderr is given)', ->
      it 'sets .stderr_pipe for the process to a fd', ->
        p = spawn.async_with_pipes {
          argv: {'sh', '-c', 'echo foo >&2'},
          read_stderr: true,
          flags: { 'SEARCH_PATH', 'STDOUT_TO_DEV_NULL' }
        }
        assert.is_not_nil p.stderr_pipe
        stderr = InputStream p.stderr_pipe
        assert.equals 'foo\n', stderr\read_all!

    context 'when .env is set', ->
      it 'spawns the process with the set values as the environment', ->
        p = spawn.async_with_pipes {
          argv: { shell, '-c', 'echo $MY_SOLE_VAR' },
          read_stdout: true,
          flags: { 'SEARCH_PATH' },
          env: { MY_SOLE_VAR: 'alone' }
        }
        stdout = InputStream p.stdout_pipe
        assert.equals 'alone\n', stdout\read_all!

    context 'when .working_dir is set', ->
      it 'spawns the process with the value as the working directory', ->
        working_directory, expected_directory = if jit.os == 'Windows'
          'C:\\', '/c'
        else
          '/etc', '/etc'
        p = spawn.async_with_pipes {
          argv: { 'pwd' },
          read_stdout: true,
          flags: { 'SEARCH_PATH' },
          :working_directory
        }
        stdout = InputStream p.stdout_pipe
        assert.equals "#{expected_directory}\n", stdout\read_all!
