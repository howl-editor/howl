lsp = require 'howl.lsp'
{:Buffer, :dispatch, :mode, :signal, :Project} = howl
{:File} = howl.io
{:Editor} = howl.ui

describe 'lsp', ->
  local buffer, client, state

  before_each ->
    buffer = Buffer {}
    client = notify: spy.new ->
    state = { :client, uri: 'file:///tmp/x.py', version: 1, dirty: false, changes: {}, full: false }

  describe 'position(buffer, pos)', ->
    it 'returns the zero-based line and utf-8 byte column for pos', ->
      buffer.text = 'åäö\nxÅy'
      assert.same { line: 0, character: 0 }, lsp.position(buffer, 1)
      assert.same { line: 0, character: 4 }, lsp.position(buffer, 3)
      assert.same { line: 1, character: 3 }, lsp.position(buffer, 7)

  describe 'pos_for(buffer, position)', ->
    before_each -> buffer.text = 'åäö\nxÅy'

    it 'returns the buffer position for the zero-based line and utf-8 byte column', ->
      assert.equals 1, lsp.pos_for(buffer, { line: 0, character: 0 })
      assert.equals 3, lsp.pos_for(buffer, { line: 0, character: 4 })
      assert.equals 7, lsp.pos_for(buffer, { line: 1, character: 3 })

    it 'returns the end of the line for a character beyond it', ->
      assert.equals 4, lsp.pos_for(buffer, { line: 0, character: 99 })

    it 'returns the end of the buffer for a line beyond the last one', ->
      assert.equals 8, lsp.pos_for(buffer, { line: 2, character: 0 })

  describe 'server_for(buffer)', ->
    local dir, project
    servers = {
      { name: 'howl-other', command: 'true --other', modes: 'lsp-other' },
      { name: 'howl-venv', command: 'howl-lsp-venv-server', modes: 'lsp-test' },
      { name: 'howl-missing', command: 'howl-no-such-server --stdio', modes: 'lsp-test' },
      { name: 'howl-true', command: 'true', init_options: { a: 1 }, modes: { 'lsp-other', 'lsp-test' } },
      { name: 'howl-false', command: 'false', modes: 'lsp-test' }
    }

    fields = (server) -> { server.name, server.command, server.init_options }

    fails = (server) ->
      lsp.on_exit { server_id: server.id, key: "#{server.id}@/x", failure: 'bad' }

    before_each ->
      mode.register name: 'lsp-test', create: -> {}
      dir = File.tmpdir!
      Project.add_root dir
      buffer.file = dir / 'x.test'
      buffer.mode = mode.by_name 'lsp-test'
      project = Project.for_file buffer.file
      lsp.register_server s for s in *servers

    after_each ->
      lsp.unregister_server s.name for s in *servers
      mode.unregister 'lsp-test'
      Project.remove_root dir
      Project.open[dir] = nil
      dir\delete_all!

    it "returns the first registered server for the buffer's mode that is installed", ->
      assert.same { 'howl-true', 'true', { a: 1 } }, fields lsp.server_for(buffer)

    it 'returns nil when none of the servers for the mode are installed', ->
      lsp.unregister_server 'howl-true'
      lsp.unregister_server 'howl-false'
      assert.is_nil lsp.server_for buffer

    it 'returns nil when no servers are registered for the mode', ->
      buffer.mode = mode.by_name 'default'
      assert.is_nil lsp.server_for buffer

    it 'returns nil for a buffer without a file, or with a file outside of any project', ->
      other = Buffer mode.by_name('lsp-test')
      assert.is_nil lsp.server_for other
      with_tmpdir (outside) ->
        other.file = outside / 'x.test'
        assert.is_nil lsp.server_for other

    it "looks for the servers' executables with the project's PATH", ->
      bin = dir / 'bin'
      bin\mkdir!
      (bin / 'howl-lsp-venv-server').contents = ''
      assert.is_nil howl.sys.find_executable 'howl-lsp-venv-server'
      project.environment = PATH: "#{bin.path}:#{howl.sys.env.PATH}"
      assert.equals 'howl-venv', lsp.server_for(buffer).name

    it "returns nil while the project's environment is being found", ->
      handle = dispatch.park 'lsp-server-env-test'
      Project.register_environment_provider name: 'lsp-test', handler: ->
        dispatch.wait handle
        {}

      status, err = pcall ->
        assert.is_nil lsp.server_for buffer
        dispatch.resume handle
        assert.equals 'howl-true', lsp.server_for(buffer).name

      Project.unregister_environment_provider 'lsp-test'
      error err unless status

    it 'returns nil when lsp_enabled is false, even with a configured lsp_server', ->
      buffer.config.lsp_enabled = false
      assert.is_nil lsp.server_for buffer
      buffer.config.lsp_server = 'howl-true'
      assert.is_nil lsp.server_for buffer

    it 'skips servers that failed to initialize', ->
      -- failures are remembered for the session, so this one is the test's own
      lsp.register_server name: 'howl-true', command: 'true --failing', modes: 'lsp-test'
      fails lsp.server_for(buffer)
      assert.equals 'howl-false', lsp.server_for(buffer).name

    it 'does not skip a failed server once its init options change', ->
      buffer.config.lsp_server = name: 'howl-true', init_options: { failing: true }
      fails lsp.server_for(buffer)
      assert.is_nil lsp.server_for buffer
      buffer.config.lsp_server = name: 'howl-true', init_options: { failing: false }
      assert.is_not_nil lsp.server_for buffer

    it 'gives the same id to equal definitions, and another to different ones', ->
      id_of = (server) ->
        buffer.config.lsp_server = server
        lsp.server_for(buffer).id

      id = id_of name: 'x', command: 'x', init_options: { a: 1, b: { 2, 3 } }
      assert.equals id, id_of name: 'x', command: 'x', init_options: { b: { 2, 3 }, a: 1 }
      assert.not_equals id, id_of name: 'x', command: 'x', init_options: { a: 1, b: { 3, 2 } }
      assert.not_equals id, id_of name: 'x', command: 'x'
      assert.not_equals id, id_of name: 'x', command: 'x --other', init_options: { a: 1, b: { 2, 3 } }
      assert.not_equals id, id_of name: 'y', command: 'x', init_options: { a: 1, b: { 2, 3 } }

    context 'with a configured lsp_server', ->
      it 'returns the registered server of that name, even when not installed or for another mode', ->
        buffer.config.lsp_server = 'howl-missing'
        assert.same { 'howl-missing', 'howl-no-such-server --stdio' }, fields lsp.server_for(buffer)
        buffer.config.lsp_server = 'howl-other'
        assert.same { 'howl-other', 'true --other' }, fields lsp.server_for(buffer)

      it 'returns nil and warns once for a name that is not registered', ->
        buffer.config.lsp_server = 'howl-unknown-server'
        warn = spy.on log, 'warn'
        status, err = pcall ->
          assert.is_nil lsp.server_for buffer
          assert.is_nil lsp.server_for buffer
        log.warn\revert!
        error err unless status
        assert.spy(warn).was_called(1)
        assert.includes warn.calls[1].vals[1], "'howl-unknown-server'"

      it 'fills in a definition from the registered server of the same name', ->
        buffer.config.lsp_server = name: 'howl-true', init_options: { b: 2 }
        assert.same { 'howl-true', 'true', { b: 2 } }, fields lsp.server_for(buffer)

        buffer.config.lsp_server = name: 'howl-true', command: 'true --changed'
        assert.same { 'howl-true', 'true --changed', { a: 1 } }, fields lsp.server_for(buffer)

      it 'returns a definition for a server that is not registered as is', ->
        buffer.config.lsp_server = name: 'other', command: 'howl-other-server', init_options: { c: 3 }
        assert.same { 'other', 'howl-other-server', { c: 3 } }, fields lsp.server_for(buffer)

      it 'returns nil for a definition with no command of its own or from the registry', ->
        buffer.config.lsp_server = name: 'howl-no-command', init_options: { c: 3 }
        warn = spy.on log, 'warn'
        status, err = pcall -> assert.is_nil lsp.server_for buffer
        log.warn\revert!
        error err unless status
        assert.spy(warn).was_called(1)

      it "uses the mode's servers when lsp_server is blank", ->
        buffer.config.lsp_server = ''
        assert.equals 'howl-true', lsp.server_for(buffer).name

      it 'can only be a name or a definition with a name', ->
        assert.raises 'lsp_server', -> buffer.config.lsp_server = { command: 'true' }
        assert.raises 'lsp_server', -> buffer.config.lsp_server = 1

  describe 'register_server(server)', ->
    it 'requires a name, a command and modes', ->
      assert.raises 'name', -> lsp.register_server command: 'x', modes: 'm'
      assert.raises 'command', -> lsp.register_server name: 'x', modes: 'm'
      assert.raises 'modes', -> lsp.register_server name: 'x', command: 'x'

    it 'replaces a server registered with the same name, keeping its place', ->
      mode.register name: 'lsp-test', create: -> {}
      buffer.mode = mode.by_name 'lsp-test'
      with_tmpdir (dir) ->
        Project.add_root dir
        buffer.file = dir / 'x.test'
        lsp.register_server name: 'howl-first', command: 'true', modes: 'lsp-test'
        lsp.register_server name: 'howl-second', command: 'true --second', modes: 'lsp-test'
        status, err = pcall ->
          lsp.register_server name: 'howl-first', command: 'true --replaced', modes: 'lsp-test'
          assert.equals 'true --replaced', lsp.server_for(buffer).command

        lsp.unregister_server 'howl-first'
        lsp.unregister_server 'howl-second'
        Project.remove_root dir
        Project.open[dir] = nil
        mode.unregister 'lsp-test'
        error err unless status

  describe 'client_for(buffer)', ->
    it 'returns nil when there is no server for the buffer', ->
      assert.is_nil lsp.client_for buffer

    it 'returns nil when the buffer has no file', ->
      buffer.config.lsp_server = name: 'true', command: 'true'
      assert.is_nil lsp.client_for buffer

    it 'returns nil for a file outside of any project', ->
      with_tmpdir (dir) ->
        file = dir / 'x.py'
        file.contents = ''
        buffer.file = file
        buffer.config.lsp_server = name: 'true', command: 'true'
        assert.is_nil lsp.client_for buffer

    it 'returns the client of an attached buffer', ->
      buffer.data.lsp = state
      assert.equals client, lsp.client_for buffer

    it "starts no server while the project's environment is being found", ->
      with_tmpdir (dir) ->
        Project.add_root dir
        file = dir / 'x.py'
        file.contents = ''
        buffer.file = file
        buffer.config.lsp_server = name: 'env-test', command: 'true --lsp-env-test'
        handle = dispatch.park 'lsp-env-test'
        Project.register_environment_provider name: 'lsp-test', handler: ->
          dispatch.wait handle
          { A: '1' }

        status, err = pcall ->
          assert.is_nil lsp.client_for buffer
          assert.is_nil lsp._clients["#{lsp.server_for(buffer).id}@#{dir.path}"]
          -- the buffer isn't showing, so it isn't attached once it's found
          dispatch.resume handle
          assert.same { A: '1' }, Project.for_file(file).environment

        Project.unregister_environment_provider 'lsp-test'
        Project.remove_root dir
        Project.open[dir] = nil
        error err unless status

  describe 'on_exit(client)', ->
    it 'detaches the buffers of client, and attaches them again on their next edit', ->
      app_buffer = howl.app\new_buffer!
      client.key = 'exit-test'
      app_buffer.data.lsp = state
      lsp.on_exit client
      assert.is_nil app_buffer.data.lsp
      assert.is_true app_buffer.data.lsp_reattach
      app_buffer\append 'x'
      -- the buffer has no file, so attaching again gives no state
      assert.is_nil app_buffer.data.lsp_reattach
      howl.app\close_buffer app_buffer, true

  describe 'project environment changes', ->
    it 'stops the clients of the project, to be restarted', ->
      root = File '/tmp/proj'
      restarted = root: root, stop: spy.new ->
      other = root: File('/tmp/other'), stop: spy.new ->
      lsp._clients['env-test@/tmp/proj'] = restarted
      lsp._clients['env-test@/tmp/other'] = other
      signal.emit 'project-environment-changed', project: { :root }
      lsp._clients['env-test@/tmp/proj'] = nil
      lsp._clients['env-test@/tmp/other'] = nil
      assert.spy(restarted.stop).was_called!
      assert.is_true restarted.restarting
      assert.spy(other.stop).was_not_called!
      assert.is_nil other.restarting

  describe 'configuration changes', ->
    local app_buffer
    server = name: 'howl-lsp-test', command: 'howl-lsp-test'

    before_each ->
      app_buffer = howl.app\new_buffer!
      -- not empty, so that another new buffer doesn't replace it
      app_buffer.text = 'x'
      app_buffer.config.lsp_server = server
      client.server_id = lsp.server_for(app_buffer).id
      client.stop = spy.new ->
      app_buffer.data.lsp = state

    after_each ->
      app_buffer.data.lsp = nil
      howl.app\close_buffer app_buffer, true

    it 'keeps buffers attached to a server they should still use', ->
      lsp.refresh!
      assert.equals state, app_buffer.data.lsp
      assert.spy(client.stop).was_not_called!

    it 'detaches buffers when lsp_enabled is set to false, stopping the server', ->
      app_buffer.config.lsp_enabled = false
      assert.is_nil app_buffer.data.lsp
      assert.spy(client.stop).was_called(1)

    it 'detaches buffers when lsp_server changes to another server, stopping the old one', ->
      app_buffer.config.lsp_server = name: 'howl-lsp-other', command: 'howl-lsp-other'
      assert.is_nil app_buffer.data.lsp
      assert.spy(client.stop).was_called(1)

    it 'detaches buffers when the init options change, stopping the old server', ->
      app_buffer.config.lsp_server = name: 'howl-lsp-test', command: 'howl-lsp-test', init_options: { a: 1 }
      assert.is_nil app_buffer.data.lsp
      assert.spy(client.stop).was_called(1)

    it 'detaches buffers from a server that is unregistered, stopping it', ->
      lsp.register_server name: 'howl-lsp-test', command: 'howl-lsp-test', modes: 'lsp-none'
      app_buffer.config.lsp_server = 'howl-lsp-test'
      assert.equals state, app_buffer.data.lsp
      lsp.unregister_server 'howl-lsp-test'
      assert.is_nil app_buffer.data.lsp
      assert.spy(client.stop).was_called(1)

    it 'does not stop a server that another buffer still uses', ->
      other = howl.app\new_buffer!
      other.config.lsp_server = server
      other.data.lsp = { :client, uri: 'file:///tmp/y.py', version: 1, dirty: false, changes: {}, full: false }
      status, err = pcall ->
        app_buffer.config.lsp_server = name: 'howl-lsp-test', command: 'howl-lsp-test', init_options: { a: 1 }
        assert.is_nil app_buffer.data.lsp
        assert.equals client, other.data.lsp.client
        assert.spy(client.stop).was_not_called!

      other.data.lsp = nil
      howl.app\close_buffer other, true
      error err unless status

  describe 'attaching', ->
    local dir, app_buffer, running, key

    before_each ->
      dir = File.tmpdir!
      Project.add_root dir
      file = dir / 'x.py'
      file.contents = 'x = 1\n'
      app_buffer = howl.app\new_buffer!
      app_buffer.file = file
      app_buffer.config.lsp_server = name: 'howl-lsp-test', command: 'howl-lsp-test'
      -- a running client for the buffer, so that attaching starts no process
      server_id = lsp.server_for(app_buffer).id
      running = :server_id, notify: spy.new(->), completion_triggers: {}
      key = "#{server_id}@#{dir.path}"
      lsp._clients[key] = running

    after_each ->
      lsp.detach app_buffer
      howl.app\close_buffer app_buffer, true
      lsp._clients[key] = nil
      Project.remove_root dir
      Project.open[dir] = nil
      dir\delete_all!

    it 'does not attach a buffer when its file is opened', ->
      signal.emit 'file-opened', file: app_buffer.file, buffer: app_buffer
      assert.is_nil app_buffer.data.lsp

    it 'attaches a buffer when an editor shows it', ->
      editor = Editor Buffer {}
      editor.buffer = app_buffer
      editor\release!
      attached = app_buffer.data.lsp
      assert.equals running, attached.client
      assert.spy(running.notify).was_called_with running, 'textDocument/didOpen', {
        textDocument: { uri: attached.uri, languageId: 'default', version: 1, text: 'x = 1\n' }
      }

    it 'attaches the showing buffers again when a restarting client exits, but not otherwise', ->
      editor = Editor Buffer {}
      editor.buffer = app_buffer
      status, err = pcall ->
        for restarting in *{ false, true }
          exiting = key: 'exiting', stopping: true, :restarting, notify: spy.new ->
          app_buffer.data.lsp.client = exiting
          lsp.on_exit exiting
          if restarting
            assert.equals running, app_buffer.data.lsp.client
          else
            assert.is_nil app_buffer.data.lsp
            lsp.attach app_buffer

      editor\release!
      error err unless status

    it 'does not attach a buffer previewed in an editor', ->
      editor = Editor Buffer {}
      editor\preview app_buffer
      editor\release!
      assert.is_nil app_buffer.data.lsp

    it 'does not attach a hidden buffer on configuration or mode changes, or saves', ->
      lsp.refresh!
      assert.is_nil app_buffer.data.lsp

      mode.register name: 'lsp-test', create: -> {}
      app_buffer.mode = mode.by_name 'lsp-test'
      mode.unregister 'lsp-test'
      assert.is_nil app_buffer.data.lsp

      app_buffer\save!
      assert.is_nil app_buffer.data.lsp

  describe 'stop_idle(now)', ->
    local idle, busy

    before_each ->
      idle = stop: spy.new(->), last_used: 0
      busy = stop: spy.new(->), last_used: 100 * 60
      lsp._clients.idle = idle
      lsp._clients.busy = busy

    after_each ->
      lsp._clients.idle = nil
      lsp._clients.busy = nil
      howl.config.lsp_server_idle_stop = nil

    it 'stops clients not used for lsp_server_idle_stop minutes', ->
      howl.config.lsp_server_idle_stop = 30
      lsp.stop_idle 100 * 60 + 1
      assert.spy(idle.stop).was_called(1)
      assert.spy(busy.stop).was_not_called!

    it 'stops nothing when lsp_server_idle_stop is 0', ->
      howl.config.lsp_server_idle_stop = 0
      lsp.stop_idle 100 * 60 + 1
      assert.spy(idle.stop).was_not_called!

  describe 'sync(buffer)', ->
    sent_changes = ->
      assert.spy(client.notify).was_called(1)
      method, params = client.notify.calls[1].vals[2], client.notify.calls[1].vals[3]
      assert.equals 'textDocument/didChange', method
      params.contentChanges

    range = (l1, c1, l2, c2) ->
      { start: { line: l1, character: c1 }, ['end']: { line: l2, character: c2 } }

    -- applies LSP content changes to text, the way a server would
    apply = (text, changes) ->
      doc = Buffer {}
      doc.text = text
      pos_for = (p) ->
        line = doc.lines[p.line + 1]
        doc\char_offset line.byte_start_pos + p.character
      for c in *changes
        start_pos = pos_for c.range.start
        doc\delete start_pos, pos_for(c.range['end']) - 1
        doc\insert c.text, start_pos
      doc.text

    it 'sends the full text with a new version when the server lacks incremental sync', ->
      buffer.text = 'hello'
      buffer.data.lsp = state
      lsp.sync buffer
      assert.spy(client.notify).was_not_called!

      buffer\append ' world'
      assert.is_true state.dirty
      lsp.sync buffer
      assert.spy(client.notify).was_called_with client, 'textDocument/didChange', {
        textDocument: { uri: 'file:///tmp/x.py', version: 2 },
        contentChanges: { { text: 'hello world' } }
      }
      assert.is_false state.dirty

      lsp.sync buffer
      assert.spy(client.notify).was_called(1)

    it 'sends the full text when the sync kind is given as a number', ->
      client.capabilities = textDocumentSync: 1
      buffer.text = 'hello'
      buffer.data.lsp = state
      buffer\append '!'
      lsp.sync buffer
      assert.same { { text: 'hello!' } }, sent_changes!

    context 'when the server supports incremental sync', ->
      before_each ->
        client.capabilities = textDocumentSync: { change: 2 }
        buffer.text = 'åäö\nxÅy'
        buffer.data.lsp = state

      it 'sends inserts as empty ranges with utf-8 byte columns', ->
        buffer\insert 'Z', 3
        lsp.sync buffer
        assert.same { { range: range(0, 4, 0, 4), text: 'Z' } }, sent_changes!

      it 'sends deletes as ranges with empty text', ->
        buffer\delete 6, 7
        lsp.sync buffer
        assert.same { { range: range(1, 1, 1, 4), text: '' } }, sent_changes!

      it 'sends replacements as a single change', ->
        buffer\change 2, 3, ->
          buffer\delete 2, 3
          buffer\insert 'bc', 2
        lsp.sync buffer
        assert.same { { range: range(0, 2, 0, 6), text: 'bc' } }, sent_changes!

      it 'handles changes spanning lines', ->
        buffer\delete 3, 6
        buffer\insert '1\n22\r\n3', 3
        lsp.sync buffer
        assert.same {
          { range: range(0, 4, 1, 3), text: '' },
          { range: range(0, 4, 0, 4), text: '1\n22\r\n3' }
        }, sent_changes!

      it 'sends all pending changes in order, once', ->
        old_text = buffer.text
        buffer\insert 'a\nb', 1
        buffer\delete 4, 6
        buffer\append '\nend'
        buffer\change 1, 2, ->
          buffer\delete 1, 2
          buffer\insert 'X', 1
        buffer\undo!
        lsp.sync buffer
        assert.equals buffer.text, apply(old_text, sent_changes!)

        lsp.sync buffer
        assert.spy(client.notify).was_called(1)

      it 'sends the full text when there are too many pending changes', ->
        buffer\append 'x' for _ = 1, 101
        lsp.sync buffer
        assert.same { { text: buffer.text } }, sent_changes!
        assert.same {}, state.changes

      it 'sends the full text when an edit splits a "\\r\\n" pair', ->
        buffer.text = 'a\rb'
        lsp.sync buffer
        client.notify\clear!
        buffer\insert '\n', 3
        lsp.sync buffer
        assert.same { { text: 'a\r\nb' } }, sent_changes!

  describe 'detach(buffer)', ->
    it 'sends didClose and forgets the buffer', ->
      buffer.data.lsp = state
      lsp.detach buffer
      assert.spy(client.notify).was_called_with client, 'textDocument/didClose', {
        textDocument: { uri: 'file:///tmp/x.py' }
      }
      assert.is_nil buffer.data.lsp

    it 'clears the diagnostics for the buffer', ->
      buffer.text = 'hello'
      buffer.markers\add {
        { name: 'inspection', source: 'lsp', start_offset: 1, end_offset: 3 }
      }
      buffer.data.lsp = state
      lsp.detach buffer
      assert.same {}, buffer.markers.all

  describe 'on_diagnostics(client, params)', ->
    local params

    lsp_markers = -> buffer.markers\find name: 'inspection', source: 'lsp'

    before_each ->
      buffer = howl.app\new_buffer!
      buffer.text = 'hello\nworld'
      buffer.data.lsp = state
      params = {
        uri: state.uri,
        diagnostics: {
          {
            range: { start: { line: 1, character: 1 }, ['end']: { line: 1, character: 3 } },
            message: 'oops'
          }
        }
      }

    after_each ->
      buffer.data.lsp = nil
      howl.app\close_buffer buffer, true

    it 'marks the diagnostics in the buffer with the matching uri', ->
      lsp.on_diagnostics client, params
      markers = lsp_markers!
      assert.equals 1, #markers
      assert.same {8, 10, 'oops', 'error'}, {
        markers[1].start_offset, markers[1].end_offset, markers[1].message, markers[1].flair
      }

    it 'ignores diagnostics for another client or uri', ->
      lsp.on_diagnostics {}, params
      params.uri = 'file:///tmp/other.py'
      lsp.on_diagnostics client, params
      assert.same {}, lsp_markers!

    it 'ignores diagnostics while the buffer has unsynced changes', ->
      state.dirty = true
      lsp.on_diagnostics client, params
      assert.same {}, lsp_markers!

    it 'ignores diagnostics for another version of the document', ->
      params.version = 7
      lsp.on_diagnostics client, params
      assert.same {}, lsp_markers!
      params.version = 1
      lsp.on_diagnostics client, params
      assert.equals 1, #lsp_markers!
