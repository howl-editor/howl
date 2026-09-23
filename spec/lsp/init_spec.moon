lsp = require 'howl.lsp'
{:Buffer} = howl

describe 'lsp', ->
  local buffer, client, state

  before_each ->
    buffer = Buffer {}
    client = notify: spy.new ->
    state = { :client, uri: 'file:///tmp/x.py', version: 1, dirty: false }

  describe 'position(buffer, pos)', ->
    it 'returns the zero-based line and utf-8 byte column for pos', ->
      buffer.text = 'åäö\nxÅy'
      assert.same { line: 0, character: 0 }, lsp.position(buffer, 1)
      assert.same { line: 0, character: 4 }, lsp.position(buffer, 3)
      assert.same { line: 1, character: 3 }, lsp.position(buffer, 7)

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
    it 'sends the full text with a new version once the buffer is modified', ->
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
