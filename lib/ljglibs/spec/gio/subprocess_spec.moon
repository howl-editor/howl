-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

glib = require 'ljglibs.glib'

return unless glib.check_version 2, 40, 0

gio = require 'ljglibs.gio'
bit = require 'bit'
import Subprocess from gio

run = (...) ->
  process = Subprocess(Subprocess.FLAGS_STDOUT_SILENCE, ...)
  process\wait!
  process

describe 'Subprocess', ->
  setup -> set_howl_loop!

  describe 'creation', ->
    it 'raises an error for an unknown command', ->
      assert.raises 'howlblargh', -> Subprocess nil, 'howlblargh', 'urk'

    it 'returns a Subprocess for a valid command', ->
      assert.not_nil Subprocess(Subprocess.FLAGS_STDOUT_SILENCE, 'id')

  describe 'wait()', ->
    it 'waits until the process is finished and returns true', ->
      process = Subprocess(Subprocess.FLAGS_STDOUT_SILENCE, 'id')
      assert.is_true process\wait!

      process = Subprocess(nil, 'false')
      assert.is_true process\wait!

  describe 'wait_async(callback)', ->
    it 'invokes <callback> with the async result when the process exits', (done) ->
      process = Subprocess(Subprocess.FLAGS_STDOUT_SILENCE, 'id')
      process\wait_async async (result) ->
        done!
        assert.is_true process\wait_finish result

  describe '.succesful', ->
    it 'is true if the process exited cleanly with a zero exit code', ->
      assert.is_true run('id').succesful

    it 'is false if the process exited with a non-zero exit code', ->
      assert.is_false run('false').succesful

  describe '.exit_status', ->
    it 'returns the exit code of the process', ->
      assert.equal 0, run('id').exit_status
      assert.not_equal 0, run('false').exit_status

  context 'signal handling', ->
    describe 'send_signal(signal) and .if_signaled', ->
      it 'sends the specified signal to the process', ->
        process = Subprocess(Subprocess.FLAGS_STDIN_PIPE, 'cat')
        process\send_signal 9
        process\wait!
        assert.is_true process.if_signaled

      it '.if_signaled returns false for a non-signaled process', ->
        assert.is_false run('id').if_signaled

      it '.term_sig holds the signal used for terminating the process', ->
        process = Subprocess(Subprocess.FLAGS_STDIN_PIPE, 'cat')
        process\send_signal 9
        process\wait!
        assert.equal 9, process.term_sig

  describe 'force_exit()', ->
    it 'tries to terminate the process in some way', ->
      process = Subprocess(Subprocess.FLAGS_STDIN_PIPE, 'cat')
      process\force_exit!
      process\wait!
      assert.is_true process.if_signaled

  describe 'wait_check()', ->
    it 'waits until the process is finished and returns true for a succesful termination', ->
      process = Subprocess(Subprocess.FLAGS_STDOUT_SILENCE, 'id')
      assert.is_true process\wait_check!

      process = Subprocess(Subprocess.FLAGS_STDOUT_SILENCE, 'false')
      assert.raises 'exited', -> process\wait_check!

    it 'raises an error if the process was killed by a signal', ->
      process = Subprocess(Subprocess.FLAGS_STDIN_PIPE, 'cat')
      process\send_signal 9
      assert.raises 'killed', -> process\wait_check!

  describe '.stdout_pipe', ->
    it 'allows reading process output', ->
      process = Subprocess(Subprocess.FLAGS_STDOUT_PIPE, 'echo', 'yay!')
      assert.equals 'yay!\n', process.stdout_pipe\read_all!

    it 'allows reading process output asynchronously', (done) ->
      process = Subprocess(bit.bor(Subprocess.FLAGS_STDOUT_PIPE, Subprocess.FLAGS_STDIN_PIPE), 'cat')
      process.stdout_pipe\read_async 4096, async (status, out) ->
        assert.equals "written\n", out
        done!

      with process.stdin_pipe
        \write_all 'written\n'
        \close!

  describe '.stderr_pipe', ->
    it 'allows reading process error output', ->
      process = Subprocess(Subprocess.FLAGS_STDERR_PIPE, 'sh', '-c', 'echo foo >&2')
      assert.equals 'foo\n', process.stderr_pipe\read_all!

  describe '.stdin_pipe', ->
    it 'allows writing to the process input', ->
      flags = bit.bor(Subprocess.FLAGS_STDOUT_PIPE, Subprocess.FLAGS_STDIN_PIPE)
      process = Subprocess(flags, 'cat')
      with process.stdin_pipe
        \write_all 'round-trip'
        \close!
      assert.equals 'round-trip', process.stdout_pipe\read_all!

  describe '<stdout, stderr> communicate(opts)', ->
    context 'when FLAGS_STDOUT_PIPE was specified', ->
      it 'returns the output as a string if requested', ->
        process = Subprocess(Subprocess.FLAGS_STDOUT_PIPE, 'echo', 'yay!')
        out = process\communicate capture_stdout: true
        assert.equals 'yay!\n', out

    context 'when FLAGS_STDERR_PIPE was specified', ->
      it 'returns the error output as a string if requested', ->
        process = Subprocess(Subprocess.FLAGS_STDERR_PIPE, 'sh', '-c', 'echo foo >&2')
        _, err = process\communicate capture_stderr: true
        assert.equals 'foo\n', err

    context 'when FLAGS_STDIN_PIPE is specified', ->
      it 'passes opts.stdin as stdin to the process', ->
        flags = { 'FLAGS_STDOUT_PIPE', 'FLAGS_STDIN_PIPE' }
        process = Subprocess(flags, 'cat')
        out = process\communicate stdin: 'catz!', capture_stdout: true
        assert.equals 'catz!', out

  describe 'communicate_async(opts, callback)', ->
    context 'when FLAGS_STDOUT_PIPE was specified', ->
      it '*_finish(result) returns the output as a string if requested', (done) ->
        process = Subprocess(Subprocess.FLAGS_STDOUT_PIPE, 'echo', 'yay!')
        process\communicate_async { capture_stdout: true }, async (status, out) ->
          done!
          assert.is_true status
          assert.equals 'yay!\n', out

    context 'when FLAGS_STDERR_PIPE was specified', ->
      it 'returns the error output as a string if requested', (done) ->
        process = Subprocess(Subprocess.FLAGS_STDERR_PIPE, 'sh', '-c', 'echo foo >&2')
        process\communicate_async { capture_stderr: true }, async (status, out, err) ->
          done!
          assert.is_true status
          assert.equals 'foo\n', err

    context 'when FLAGS_STDIN_PIPE is specified', ->
      it 'passes opts.stdin as stdin to the process', (done) ->
        flags = bit.bor(Subprocess.FLAGS_STDOUT_PIPE, Subprocess.FLAGS_STDIN_PIPE)
        process = Subprocess(flags, 'cat')
        process\communicate_async { stdin: 'catz!', capture_stdout: true }, async (status, out) ->
          done!
          assert.is_true status
          assert.equals 'catz!', out
