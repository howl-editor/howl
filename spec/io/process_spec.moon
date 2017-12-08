Process = howl.io.Process
File = howl.io.File
glib = require 'ljglibs.glib'

describe 'Process', ->

  run = (...) ->
    with Process cmd: ...
      \wait!

  describe 'Process(opts)', ->
    it 'raises an error if opts.cmd is missing or invalid', ->
      assert.raises 'cmd', -> Process {}
      assert.raises 'cmd', -> Process cmd: 2
      assert.not_error -> Process cmd: 'id'
      assert.not_error -> Process cmd: {'echo', 'foo'}

    it 'returns a process object', ->
      assert.equal 'Process', typeof Process cmd: 'true'

    it 'raises an error for an unknown command', ->
      assert.raises 'howlblargh', -> Process cmd: {'howlblargh'}

    it 'sets .argv to the parsed command line', ->
      p = Process cmd: {'echo', 'foo'}
      assert.same {'echo', 'foo'}, p.argv

      p = Process cmd: 'echo "foo bar"'
      assert.same { '/bin/sh', '-c', 'echo "foo bar"'}, p.argv

    it 'allows specifying a different shell', ->
      p = Process cmd: 'foo', shell: '/bin/echo'
      assert.same { '/bin/echo', '-c', 'foo'}, p.argv

  describe 'Process.open_pipe(cmd, opts)', ->
    it 'creates a process set up for piping', (done) ->
      howl_async ->
        p = Process.open_pipe {'sh', '-c', 'cat; echo foo >&2'}, stdin: 'reverb'
        out, err = p\pump!
        assert.equal 'reverb', out
        assert.equal 'foo\n', err
        assert.equal 'Process', typeof(p)
        done!

  describe 'Process.execute(cmd, opts)', ->
    it 'executes the specified command and return <out, err, process>', (done) ->
      howl_async ->
        out, err, p = Process.execute {'sh', '-c', 'cat; echo foo >&2'}, stdin: 'reverb'
        assert.equal 'reverb', out
        assert.equal 'foo\n', err
        assert.equal 'Process', typeof(p)
        done!

    it "executes string commands using /bin/sh by default", (done) ->
      howl_async ->
        status, out = pcall Process.execute, 'echo $0'
        assert.is_true status
        assert.equal '/bin/sh\n', out
        done!

    it "allows specifying a different shell", (done) ->
      howl_async ->
        status, out, _, process = pcall Process.execute, 'blargh', shell: '/bin/echo'
        assert.is_true status
        assert.match out, 'blargh'
        assert.equal 'blargh', process.command_line
        done!

    it 'opts.working_directory sets the working working directory', (done) ->
      howl_async ->
        with_tmpdir (dir) ->
          out = Process.execute 'pwd', working_directory: dir
          assert.equal dir.path, out.stripped
          done!

    it 'opts.env sets the process environment', (done) ->
      howl_async ->
        out = Process.execute {'env'}, env: { foo: 'bar' }
        assert.equal 'foo=bar', out.stripped
        done!

    it 'works with large process outputs', (done) ->
      howl_async ->
        File.with_tmpfile (f) ->
          file_contents = string.rep "xxxxxxxxxxxxxxxxxxxxxxxxxx yyyyyyyyyyyyyyyyyyy zzzzzzzzzzzzzzzzzzz\n", 5000
          f.contents = file_contents
          status, out = pcall Process.execute, "cat #{f.path}"
          assert.is_true status
          assert.equal file_contents, out
          done!

  describe 'pump(on_stdout, on_stderr)', ->

    context 'when the <on_stdout> handler is provided', ->
      it 'invokes the handler for any stdout output before returning', (done) ->
        howl_async ->
          on_stdout = spy.new -> nil
          p = Process cmd: 'echo foo', read_stdout: true
          p\pump on_stdout
          assert.is_true p.exited
          assert.spy(on_stdout).was_called_with 'foo\n'
          assert.spy(on_stdout).was_called_with nil
          done!

    context 'when the <on_stderr> handler is provided', ->
      it 'invokes the handler for any stderr output before returning', (done) ->
        howl_async ->
          on_stderr = spy.new -> nil
          p = Process cmd: 'echo err >&2', read_stderr: true
          p\pump nil, on_stderr
          assert.is_true p.exited
          assert.spy(on_stderr).was_called_with 'err\n'
          assert.spy(on_stderr).was_called_with nil
          done!

    context 'when both handlers are provided', ->
      it 'invokes both handlers for any output before returning', (done) ->
        howl_async ->
          on_stdout = spy.new -> nil
          on_stderr = spy.new -> nil
          p = Process cmd: 'echo out; echo err >&2', read_stdout: true, read_stderr: true
          p\pump on_stdout, on_stderr
          assert.is_true p.exited
          assert.spy(on_stdout).was_called_with 'out\n'
          assert.spy(on_stdout).was_called_with nil
          assert.spy(on_stderr).was_called_with 'err\n'
          assert.spy(on_stderr).was_called_with nil
          done!

    context 'when handlers are not specified', ->
      it 'collects and returns <out> and <err> output', ->
        p = Process cmd: 'echo foo', read_stdout: true
        stdout, stderr = p\pump!
        assert.equals 'foo\n', stdout
        assert.is_nil stderr

        p = Process cmd: 'echo err >&2', read_stderr: true
        stdout, stderr = p\pump!
        assert.equals 'err\n', stderr
        assert.is_nil stdout

        p = Process cmd: 'echo out; echo err >&2', read_stdout: true, read_stderr: true
        stdout, stderr = p\pump!
        assert.equals 'out\n', stdout
        assert.equals 'err\n', stderr

  describe 'pump_lines(on_stdout, on_stderr)', ->
    it 'invokes the handler for any stdout output before returning', (done) ->
      howl_async ->
        on_stdout = spy.new -> nil
        p = Process cmd: 'echo "foo\nbar"', read_stdout: true
        p\pump_lines on_stdout
        assert.is_true p.exited
        assert.spy(on_stdout).was_called_with {'foo', 'bar'}
        done!

    it 'invokes the handler for any stderr output before returning', (done) ->
      howl_async ->
        on_stderr = spy.new -> nil
        p = Process cmd: 'echo "err1\nerr2" >&2', read_stderr: true
        p\pump_lines nil, on_stderr
        assert.is_true p.exited
        assert.spy(on_stderr).was_called_with {'err1', 'err2'}
        done!

    it 'handles CRLFs', (done) ->
      howl_async ->
        on_stdout = spy.new -> nil
        p = Process cmd: 'echo "one\r\ntwo"', read_stdout: true
        p\pump_lines on_stdout
        assert.spy(on_stdout).was_called_with {'one', 'two'}
        done!

    it 'returns empty lines as empty lines', (done) ->
      howl_async ->
        on_stdout = spy.new -> nil
        p = Process cmd: 'echo "one\n\nthree"', read_stdout: true
        p\pump_lines on_stdout
        assert.spy(on_stdout).was_called_with {'one', '', 'three'}
        done!

    it 'assembles lines correctly for larger reads', (done) ->
      howl_async ->
        File.with_tmpfile (f) ->
          lines = ["line #{i}" for i = 1, 4000]
          f.contents = table.concat lines, '\n'
          passed_lines = {}
          on_stdout = (_lines) ->
            for l in *_lines
              table.insert passed_lines, l

          p = Process cmd: "cat '#{f.path}'", read_stdout: true
          p\pump_lines on_stdout
          for i = 1, 4000
            assert.equal lines[i], passed_lines[i]
          done!

    context 'when handlers are not specified', ->
      it 'collects and returns <out> and <err> output as lines', ->
        p = Process cmd: 'echo "one\ntwo"', read_stdout: true
        stdout, stderr = p\pump_lines!
        assert.same {'one', 'two'}, stdout
        assert.equals 0, #stderr

        p = Process cmd: 'echo "one\ntwo" >&2', read_stderr: true
        stdout, stderr = p\pump_lines!
        assert.same {'one', 'two'}, stderr
        assert.equals 0, #stdout

        p = Process cmd: 'echo "one\ntwo"; echo "three" >&2', read_stdout: true, read_stderr: true
        stdout, stderr = p\pump_lines!
        assert.same {'one', 'two'}, stdout
        assert.same {'three'}, stderr

  describe 'wait()', ->
    it 'waits until the process is finished', (done) ->
      settimeout 2
      howl_async ->
        File.with_tmpfile (file) ->
          file\delete!
          p = Process cmd: { 'sh', '-c', "sleep 1; touch '#{file.path}'" }
          p\wait!
          assert.is_true file.exists
          done!

  context 'signal handling', ->
    describe 'send_signal(signal) and .signalled', ->
      it 'sends the specified signal to the process', (done) ->
        howl_async ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.is_true p.signalled
          done!

      it '.signalled is false for a non-signaled process', (done) ->
        howl_async ->
          p = Process cmd: 'id'
          p\wait!
          assert.is_false p.signalled
          done!

      it '.signal holds the signal used for terminating the process', (done) ->
        howl_async ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.equals 9, p.signal
          done!

      it '.signal_name holds the name of the signal used for terminating the process', (done) ->
        howl_async ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.equals 'KILL', p.signal_name
          done!

      it 'signals can be referred to by name as well', (done) ->
        howl_async ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 'KILL'
          p\wait!
          assert.equals 9, p.signal
          done!

  describe '.exit_status', ->
    it 'is nil for a running process', ->
      p = Process cmd: { 'sh', '-c', "sleep 1; true" }
      assert.is_nil p.exit_status
      p\wait!

    it 'is nil for a signalled process', (done) ->
      howl_async ->
        p = Process cmd: 'cat', write_stdin: true
        p\send_signal 9
        p\wait!
        assert.is_nil p.exit_status
        done!

    it 'is set to the exit status for a normally exited process', (done) ->
      howl_async ->
        p = run 'echo foo'
        assert.equals 0, p.exit_status

        p = run {'sh', '-c', 'exit 1' }
        assert.equals 1, p.exit_status

        p = run {'sh', '-c', 'exit 2' }
        assert.equals 2, p.exit_status

        done!

  describe '.working_directory', ->
    context 'when provided during launch', ->
      it 'is the same directory', ->
        cwd = File '/bin'
        p = Process(cmd: 'true', working_directory: cwd)
        assert.equal cwd, p.working_directory

      it 'is always a File instance', ->
        p = Process(cmd: 'true', working_directory: '/bin')
        assert.equal 'File', typeof  p.working_directory

    context 'when not provided', ->
      it 'is the current working directory', ->
        p = Process(cmd: 'true')
        assert.equal File(glib.get_current_dir!), p.working_directory

  describe '.successful', ->
    it 'is true if the process exited cleanly with a zero exit code', (done) ->
      howl_async ->
        assert.is_true run('id').successful
        done!

    it 'is false if the process exited with a non-zero exit code', (done) ->
      howl_async ->
        assert.is_false run('false').successful
        done!

    it 'is false if the process exited due to a signal', (done) ->
      howl_async ->
        p = Process cmd: 'cat', write_stdin: true
        p\send_signal 9
        p\wait!
        assert.is_false p.successful
        done!

  describe '.stdout', ->
    it 'allows reading process output', (done) ->
      howl_async ->
        p = Process cmd: {'echo', 'one\ntwo'}, read_stdout: true
        assert.equals 'one\ntwo\n', p.stdout\read!
        assert.is_nil p.stdout\read!
        done!

  describe '.stderr', ->
    it 'allows reading process error output', (done) ->
      howl_async ->
        p = Process cmd: {'sh', '-c', 'echo foo >&2'}, read_stderr: true
        assert.equals 'foo\n', p.stderr\read!
        done!

  describe '.stdin', ->
    it 'allows writing to the process input', (done) ->
      howl_async ->
        p = Process cmd: {'cat'}, write_stdin: true, read_stdout: true
        with p.stdin
          \write 'round-trip'
          \close!

        assert.equals 'round-trip', p.stdout\read!
        p\wait!
        done!

  describe '.command_line', ->
    context 'when the command is specified as a string', ->
      it 'is the same', (done) ->
        howl_async ->
          assert.equal 'echo command "bar"', run('echo command "bar"').command_line
          done!

    context 'when the command is specified as a table', ->
      it 'is a created shell command line', (done) ->
        howl_async ->
          assert.equal "echo command 'bar zed'", run({'echo', 'command', 'bar zed'}).command_line
          done!

  describe '.exit_status_string', ->
    it 'provides the exit code for a normally terminated process', (done) ->
      howl_async ->
        assert.equals 'exited normally with code 0', run('id').exit_status_string
        assert.equals 'exited normally with code 1', run('exit 1').exit_status_string
        done!

    it 'provides the signal name for a killed process', (done) ->
      howl_async ->
        p = Process cmd: {'cat'}, write_stdin: true, read_stdout: true
        p\send_signal 'KILL'
        p\wait!
        assert.equals 'killed by signal 9 (KILL)', p.exit_status_string
        done!

  describe 'Process.running', ->
    it 'is a table of currently running processes, keyed by pid', (done) ->
      howl_async ->
        assert.same {}, Process.running
        p = Process cmd: {'cat'}, write_stdin: true
        assert.same {[p.pid]: p}, Process.running
        p.stdin\close!
        p\wait!
        assert.same {}, Process.running
        done!

  context 'resource management', ->

    it 'processes are collected correctly', (done) ->
      howl_async ->
        p = Process cmd: {'echo', 'one\ntwo'}, read_stdout: true
        assert.equals 'one\ntwo\n', p.stdout\read!
        p\wait!
        assert.is_nil p.stdout\read!

        list = setmetatable {p}, __mode: 'v'
        p = nil
        collect_memory!
        assert.is_nil list[1]
        done!
