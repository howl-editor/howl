Process = howl.io.Process
File = howl.io.File
glib = require 'ljglibs.glib'

sh, echo = if jit.os == 'Windows'
  if not howl.sys.env.MSYSCON
    error 'These specs must be run under MSYS!'
  "#{howl.sys.env.WD}sh.exe", "#{howl.sys.env.WD}echo.exe"
else
  '/bin/sh', '/bin/echo'

fix_paths = (path) ->
  if jit.os == 'Windows'
    -- On MSYS, often the shell will output paths like:
    -- /usr/bin/sh
    -- but the specs use (and therefore expect) stuff like:
    -- C:/msys64/usr/bin/sh.exe
    -- This fixes up those paths to make the latter like the former.
    path\gsub('\\', '/')\gsub('.*msys[^/]*/', '/')\gsub('%.exe$', '')
  else
    path

describe 'Process', ->

  run = (...) ->
    with Process cmd: ...
      \wait!

  procs = {}
  collected_process = (...) ->
    proc = Process ...
    table.insert procs, proc
    proc
  collect = ->
    for proc in *procs
      proc\wait!

  describe 'Process(opts)', ->
    it 'raises an error if opts.cmd is missing or invalid', ->
      assert.raises 'cmd', -> Process {}
      assert.raises 'cmd', -> Process cmd: 2
      assert.not_error -> collected_process cmd: 'id'
      assert.not_error -> collected_process cmd: {'echo', 'foo'}

    it 'returns a process object', ->
      assert.equal 'Process', typeof collected_process cmd: 'true'

    it 'raises an error for an unknown command', ->
      errstring = if jit.os == 'Windows'
        'No such file or directory'
      else
        'howlblargh'
      assert.raises errstring, -> Process cmd: {'howlblargh'}

    it 'sets .argv to the parsed command line', ->
      p = collected_process cmd: {'echo', 'foo'}
      assert.same {'echo', 'foo'}, p.argv

      p = collected_process cmd: 'echo "foo bar"'
      assert.same { sh, '-c', 'echo "foo bar"'}, p.argv

    it 'allows specifying a different shell', ->
      p = collected_process cmd: 'foo', shell: echo
      assert.same { echo, '-c', 'foo'}, p.argv

  describe 'Process.execute(cmd, opts)', ->
    it 'executes the specified command and return <out, err, process>', (done) ->
      proc_async ->
        out, err, p = Process.execute {sh, '-c', 'cat; echo foo >&2'}, stdin: 'reverb'
        assert.equal 'reverb', out
        assert.equal 'foo\n', err
        assert.equal 'Process', typeof(p)
        proc_done done

    it "executes string commands using /bin/sh by default", (done) ->
      proc_async ->
        status, out = pcall Process.execute, 'echo $0'
        assert.is_true status
        expected = fix_paths sh
        assert.equal "#{expected}\n", out
        proc_done done

    it "allows specifying a different shell", (done) ->
      proc_async ->
        status, out, _, process = pcall Process.execute, 'blargh', shell: echo
        assert.is_true status
        assert.match out, 'blargh'
        assert.equal 'blargh', process.command_line
        proc_done done

    it 'opts.working_directory sets the working working directory', (done) ->
      proc_async ->
        with_tmpdir (dir) ->
          out = Process.execute 'pwd', working_directory: dir
          assert.equal dir.path, out.stripped
          proc_done done

    it 'opts.env sets the process environment', (done) ->
      proc_async ->
        out = Process.execute 'env', env: { foo: 'bar' }
        assert.equal 'foo=bar', out.stripped
        proc_done done

    it 'works with large process outputs', (done) ->
      proc_async ->
        File.with_tmpfile (f) ->
          file_contents = string.rep "xxxxxxxxxxxxxxxxxxxxxxxxxx yyyyyyyyyyyyyyyyyyy zzzzzzzzzzzzzzzzzzz\n", 5000
          f.contents = file_contents
          status, out = pcall Process.execute, "cat #{f.path}"
          assert.is_true status
          assert.equal file_contents, out
          proc_done done

  describe 'pump(on_stdout, on_stderr)', ->

    context 'when the <on_stdout> handler is provided', ->
      it 'invokes the handler for any stdout output before returning', (done) ->
        proc_async ->
          on_stdout = spy.new -> nil
          p = Process cmd: 'echo foo', read_stdout: true
          p\pump on_stdout
          assert.is_true p.exited
          assert.spy(on_stdout).was_called_with 'foo\n'
          assert.spy(on_stdout).was_called_with nil
          proc_done done

    context 'when the <on_stderr> handler is provided', ->
      it 'invokes the handler for any stderr output before returning', (done) ->
        proc_async ->
          on_stderr = spy.new -> nil
          p = Process cmd: 'echo err >&2', read_stderr: true
          p\pump nil, on_stderr
          assert.is_true p.exited
          assert.spy(on_stderr).was_called_with 'err\n'
          assert.spy(on_stderr).was_called_with nil
          proc_done done

    context 'when both handlers are provided', ->
      it 'invokes both handlers for any output before returning', (done) ->
        proc_async ->
          on_stdout = spy.new -> nil
          on_stderr = spy.new -> nil
          p = Process cmd: 'echo out; echo err >&2', read_stdout: true, read_stderr: true
          p\pump on_stdout, on_stderr
          assert.is_true p.exited
          assert.spy(on_stdout).was_called_with 'out\n'
          assert.spy(on_stdout).was_called_with nil
          assert.spy(on_stderr).was_called_with 'err\n'
          assert.spy(on_stderr).was_called_with nil
          proc_done done

    context 'when handlers are not specified', ->
      it 'collects and returns <out> and <err> output', ->
        proc_async ->
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

  describe 'wait()', ->
    it 'waits until the process is finished', (done) ->
      settimeout 2
      proc_async ->
        File.with_tmpfile (file) ->
          file\delete!
          p = Process cmd: { 'sh', '-c', "sleep 1; touch '#{file.path}'" }
          p\wait!
          assert.is_true file.exists
          proc_done done

  context 'signal handling', ->
    describe 'send_signal(signal) and .signalled', ->
      it 'sends the specified signal to the process', (done) ->
        proc_async ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.is_true p.signalled
          proc_done done

      it '.signalled is false for a non-signaled process', (done) ->
        proc_async ->
          p = Process cmd: 'id'
          p\wait!
          assert.is_false p.signalled
          proc_done done

      it '.signal holds the signal used for terminating the process', (done) ->
        proc_async ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.equals 9, p.signal
          proc_done done

      it '.signal_name holds the name of the signal used for terminating the process', (done) ->
        proc_async ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 9
          p\wait!
          assert.equals 'KILL', p.signal_name
          proc_done done

      it 'signals can be referred to by name as well', (done) ->
        proc_async ->
          p = Process cmd: 'cat', write_stdin: true
          p\send_signal 'KILL'
          p\wait!
          assert.equals 9, p.signal
          proc_done done

  describe '.exit_status', ->
    it 'is nil for a running process', ->
      proc_async ->
        p = Process cmd: { 'sh', '-c', "sleep 1; true" }
        assert.is_nil p.exit_status
        p\wait!

    it 'is nil for a signalled process', (done) ->
      proc_async ->
        p = Process cmd: 'cat', write_stdin: true
        p\send_signal 9
        p\wait!
        assert.is_nil p.exit_status
        proc_done done

    it 'is set to the exit status for a normally exited process', (done) ->
      proc_async ->
        p = run 'echo foo'
        assert.equals 0, p.exit_status

        p = run {'sh', '-c', 'exit 1' }
        assert.equals 1, p.exit_status

        p = run {'sh', '-c', 'exit 2' }
        assert.equals 2, p.exit_status

        proc_done done

  describe '.working_directory', ->
    context 'when provided during launch', ->
      bindir = if jit.os == 'Windows'
        howl.sys.env.SYSTEMROOT
      else
        '/bin'

      it 'is the same directory', ->
        cwd = File bindir
        p = collected_process(cmd: 'true', working_directory: cwd)
        assert.equal cwd, p.working_directory

      it 'is always a File instance', ->
        p = collected_process(cmd: 'true', working_directory: bindir)
        assert.equal 'File', typeof p.working_directory

    context 'when not provided', ->
      it 'is the current working directory', ->
        p = collected_process(cmd: 'true')
        assert.equal File(glib.get_current_dir!), p.working_directory

  describe '.successful', ->
    it 'is true if the process exited cleanly with a zero exit code', (done) ->
      proc_async ->
        assert.is_true run('id').successful
        proc_done done

    it 'is false if the process exited with a non-zero exit code', (done) ->
      proc_async ->
        assert.is_false run('false').successful
        proc_done done

    it 'is false if the process exited due to a signal', (done) ->
      proc_async ->
        p = Process cmd: 'cat', write_stdin: true
        p\send_signal 9
        p\wait!
        assert.is_false p.successful
        proc_done done

  describe '.stdout', ->
    it 'allows reading process output', (done) ->
      proc_async ->
        p = collected_process cmd: {'echo', 'one\ntwo'}, read_stdout: true
        assert.equals 'one\ntwo\n', p.stdout\read!
        assert.is_nil p.stdout\read!
        proc_done done

  describe '.stderr', ->
    it 'allows reading process error output', (done) ->
      proc_async ->
        p = collected_process cmd: {'sh', '-c', 'echo foo >&2'}, read_stderr: true
        assert.equals 'foo\n', p.stderr\read!
        proc_done done

  describe '.stdin', ->
    it 'allows writing to the process input', (done) ->
      proc_async ->
        p = Process cmd: {'cat'}, write_stdin: true, read_stdout: true
        with p.stdin
          \write 'round-trip'
          \close!

        assert.equals 'round-trip', p.stdout\read!
        p\wait!
        proc_done done

  describe '.command_line', ->
    context 'when the command is specified as a string', ->
      it 'is the same', (done) ->
        proc_async ->
          assert.equal 'echo command "bar"', run('echo command "bar"').command_line
          proc_done done

    context 'when the command is specified as a table', ->
      it 'is a created shell command line', (done) ->
        proc_async ->
          assert.equal "echo command 'bar zed'", run({'echo', 'command', 'bar zed'}).command_line
          proc_done done

  describe '.exit_status_string', ->
    it 'provides the exit code for a normally terminated process', (done) ->
      proc_async ->
        assert.equals 'exited normally with code 0', run('id').exit_status_string
        assert.equals 'exited normally with code 1', run('exit 1').exit_status_string
        proc_done done

    it 'provides the signal name for a killed process', (done) ->
      proc_async ->
        p = Process cmd: {'cat'}, write_stdin: true, read_stdout: true
        p\send_signal 'KILL'
        p\wait!
        assert.equals 'killed by signal 9 (KILL)', p.exit_status_string
        proc_done done

  describe 'Process.running', ->
    it 'is a table of currently running processes, keyed by pid', (done) ->
      proc_async ->
        collect!
        assert.same {}, Process.running
        p = Process cmd: {'cat'}, write_stdin: true
        assert.same {[p.pid]: p}, Process.running
        p.stdin\close!
        p\wait!
        assert.same {}, Process.running
        proc_done done

  context 'resource management', ->

    it 'processes are collected correctly', (done) ->
      proc_async ->
        p = Process cmd: {'echo', 'one\ntwo'}, read_stdout: true
        assert.equals 'one\ntwo\n', p.stdout\read!
        p\wait!
        assert.is_nil p.stdout\read!

        list = setmetatable {p}, __mode: 'v'
        p = nil
        collect_memory!
        assert.is_nil list[1]
        proc_done done
