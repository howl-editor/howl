lsp = require 'howl.lsp'
{:Buffer, :mode} = howl

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

  describe 'command_for(buffer)', ->
    use_servers = (servers) ->
      mode.register name: 'lsp-test', create: -> lsp_servers: servers
      buffer.mode = mode.by_name 'lsp-test'

    before_each -> use_servers { 'howl-no-such-server --stdio', 'true', 'false' }
    after_each -> mode.unregister 'lsp-test'

    it "returns the first installed server of the mode's lsp_servers", ->
      assert.equals 'true', lsp.command_for buffer

    it 'returns nil when none of the servers are installed', ->
      use_servers { 'howl-no-such-server' }
      assert.is_nil lsp.command_for buffer

    it 'returns nil when the mode has no lsp_servers', ->
      buffer.mode = mode.by_name 'default'
      assert.is_nil lsp.command_for buffer

    it 'returns a configured lsp_command even when not installed', ->
      buffer.config.lsp_command = 'howl-no-such-server --stdio'
      assert.equals 'howl-no-such-server --stdio', lsp.command_for buffer

    it 'returns nil when lsp_command is blank', ->
      buffer.config.lsp_command = ''
      assert.is_nil lsp.command_for buffer

  describe 'client_for(buffer)', ->
    it 'returns nil when no lsp_command is set', ->
      assert.is_nil lsp.client_for buffer

    it 'returns nil when the buffer has no file', ->
      buffer.config.lsp_command = 'true'
      assert.is_nil lsp.client_for buffer

    it 'returns the client of an attached buffer', ->
      buffer.data.lsp = state
      assert.equals client, lsp.client_for buffer

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
