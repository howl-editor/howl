{:ProcessListBuffer, :Editor} = howl.ui
{:Process} = howl.io

describe 'ProcessListBuffer', ->
  local processes

  start = (title) ->
    p = Process cmd: {'cat'}, write_stdin: true, long_lived: true, :title
    table.insert processes, p
    p

  wait = (secs) ->
    h = howl.dispatch.park 'wait'
    howl.timer.after secs, -> howl.dispatch.resume h
    howl.dispatch.wait h

  stop_all = ->
    for p in *processes
      p.stdin\close!
      p\wait!

  before_each ->
    processes = {}

  it 'lists the pid and title of long-lived processes', (done) ->
    howl_async ->
      p = start 'Test server'
      buffer = ProcessListBuffer!
      assert.includes buffer.lines[2].text, tostring(p.pid)
      assert.includes buffer.lines[2].text, 'Test server'
      stop_all!
      done!

  it 'process_at(line_nr) returns the process listed on the line', (done) ->
    howl_async ->
      first, second = start('one'), start('two')
      first.started_at = second.started_at - 1
      buffer = ProcessListBuffer!
      assert.is_nil buffer\process_at 1
      assert.equals first, buffer\process_at 2
      assert.equals second, buffer\process_at 3
      stop_all!
      done!

  it 'refreshes as processes exit', (done) ->
    howl_async ->
      start 'Test server'
      buffer = ProcessListBuffer!
      stop_all!
      assert.is_nil buffer\process_at 2
      assert.includes buffer.text, 'No long-lived processes'
      done!

  it 'updates the running times every second', (done) ->
    settimeout 4
    howl_async ->
      p = start 'Test server'
      p.started_at -= 65
      buffer = ProcessListBuffer!
      assert.includes buffer.lines[2].text, '1m 05s'
      wait 1.2
      assert.includes buffer.lines[2].text, '1m 06s'
      buffer\stop_updates!
      text = buffer.text
      wait 1.2
      assert.equals text, buffer.text
      stop_all!
      done!

  it 'stops the process on the cursor line with "s"', (done) ->
    howl_async ->
      p = start 'Test server'
      p.stop_handler = spy.new ->
      buffer = ProcessListBuffer!
      editor = Editor buffer
      editor.cursor.line = 2
      buffer.mode.keymap.editor.s editor
      assert.spy(p.stop_handler).was_called(1)
      stop_all!
      editor\release!
      done!
