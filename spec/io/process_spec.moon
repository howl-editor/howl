Process = howl.io.Process
File = howl.io.File
dispatch = howl.dispatch

run = (...) ->
  with Process cmd: ...
    \wait!

in_co = (f) ->
  status, err = dispatch.launch async f
  error err unless status

describe 'Process', ->
  setup -> set_howl_loop!

  describe 'Process(opts)', ->
    it 'raises an error if opts.cmd is missing or invalid', ->
      assert.raises 'cmd', -> Process {}
      assert.raises 'cmd', -> Process cmd: 2
      assert.not_error -> Process cmd: 'id'
      assert.not_error -> Process cmd: {'echo', 'foo'}

    it 'returns a process object', ->
      assert.equal 'Process', typeof Process cmd: 'true'

    it 'raises an error for an unknown command', ->
      assert.raises 'howlblargh', -> Process cmd: 'howlblargh'

    it 'sets .argv to the parsed command line', ->
      p = Process cmd: {'echo', 'foo'}
      assert.same {'echo', 'foo'}, p.argv

      p = Process cmd: 'echo "foo bar"'
      assert.same {'echo', 'foo bar'}, p.argv

  describe 'wait()', ->
    it 'waits until the process is finished', (done) ->
      settimeout 2
      File.with_tmpfile (file) ->
        file\delete!

        in_co ->
          p = Process cmd: { 'sh', '-c', "sleep 1; touch '#{file.path}'" }
          p\wait!
          assert.is_true file.exists
          done!

  context 'signal handling', ->
    describe 'send_signal(signal) and .signalled', ->
      it 'sends the specified signal to the process', (done) ->
        in_co ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.is_true p.signalled
          done!

      it '.signalled is false for a non-signaled process', (done) ->
        in_co ->
          p = Process cmd: 'id'
          p\wait!
          assert.is_false p.signalled
          done!

      it '.signal holds the signal used for terminating the process', (done) ->
        in_co ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.equals 9, p.signal
          done!

      it '.signal_name holds the name of the signal used for terminating the process', (done) ->
        in_co ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.equals 'KILL', p.signal_name
          done!

      it 'signals can be referred to by name as well', (done) ->
        in_co ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 'KILL'
          p\wait!
          assert.equals 9, p.signal
          done!

  describe '.exit_status', ->
    it 'is nil for a running process', ->
      p = Process cmd: { 'sh', '-c', "sleep 1; true" }
      assert.is_nil p.exit_status

    it 'is nil for a signalled process', (done) ->
      in_co ->
        p = Process cmd: 'cat', write_stdin: true
        p\send_signal 9
        p\wait!
        assert.is_nil p.exit_status
        done!

    it 'is set to the exit status for a normally exited process', (done) ->
      in_co ->
        p = run 'echo foo'
        assert.equals 0, p.exit_status

        p = run 'sh -c "exit 1"'
        assert.equals 1, p.exit_status

        p = run 'sh -c "exit 2"'
        assert.equals 2, p.exit_status

        done!

  describe '.successful', ->
    it 'is true if the process exited cleanly with a zero exit code', (done) ->
      in_co ->
        assert.is_true run('id').successful
        done!

    it 'is false if the process exited with a non-zero exit code', (done) ->
      in_co ->
        assert.is_false run('false').successful
        done!

    it 'is false if the process exited due to a signal', (done) ->
      in_co ->
        p = Process cmd: 'cat', write_stdin: true
        p\send_signal 9
        p\wait!
        assert.is_false p.successful
        done!

  describe '.stdout', ->
    it 'allows reading process output', (done) ->
      in_co ->
        p = Process cmd: 'echo "one\ntwo"', read_stdout: true
        assert.equals 'one\ntwo\n', p.stdout\read!
        assert.is_nil p.stdout\read!
        done!

  describe '.stderr', ->
    it 'allows reading process error output', (done) ->
      in_co ->
        p = Process cmd: {'sh', '-c', 'echo foo >&2'}, read_stderr: true
        assert.equals 'foo\n', p.stderr\read!
        done!

  describe '.stdin', ->
    it 'allows writing to the process input', (done) ->
      in_co ->
        p = Process cmd: 'cat', write_stdin: true, read_stdout: true
        with p.stdin
          \write 'round-trip'
          \close!

        assert.equals 'round-trip', p.stdout\read!
        done!
