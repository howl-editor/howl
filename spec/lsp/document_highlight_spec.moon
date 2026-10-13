document_highlight = require 'howl.lsp.document_highlight'
match = require 'luassert.match'
{:app, :mode, :signal, :timer} = howl
append = table.insert

range = (line, s_char, e_line, e_char) -> {
  start: { :line, character: s_char },
  ['end']: { line: e_line, character: e_char }
}

describe 'lsp.document_highlight', ->
  local buffer, client, callbacks, sent, editor

  -- the markers shown, as { flair, start_offset, end_offset }
  shown = -> [{ m.flair, m.start_offset, m.end_offset } for m in *buffer.markers.all]

  move_to = (pos) ->
    editor.cursor.pos = pos
    signal.emit 'cursor-changed', :editor, cursor: editor.cursor

  answer = { { range: range(0, 0, 0, 6), kind: 3 }, { range: range(1, 6, 1, 12), kind: 2 } }

  before_each ->
    callbacks, sent = {}, {}
    client = {
      initialized: true,
      capabilities: { documentHighlightProvider: true },
      send_request: spy.new (_, method, params, callback) ->
        append sent, method
        append callbacks, callback
        #callbacks
      cancel: spy.new ->
      notify: spy.new (_, method) -> append sent, method
    }
    buffer = app\new_buffer mode.by_name 'default'
    buffer.text = 'åäö = 1\nprint(åäö)\nåäö\n'
    buffer.data.lsp = { :client, uri: 'file:///tmp/x.py', version: 1, dirty: false, changes: {}, full: false }
    editor = :buffer, cursor: { pos: 1 }

  after_each ->
    document_highlight.cancel!
    app\close_buffer buffer, true

  describe 'request(buffer, pos)', ->
    it 'requests the highlights for the uri and the utf-8 position', ->
      document_highlight.request buffer, 16
      assert.spy(client.send_request).was_called_with client, 'textDocument/documentHighlight', {
        textDocument: { uri: 'file:///tmp/x.py' },
        position: { line: 1, character: 8 }
      }, match._

    it 'sends pending changes first', ->
      buffer.data.lsp.dirty = true
      buffer.data.lsp.full = true
      document_highlight.request buffer, 16
      assert.same { 'textDocument/didChange', 'textDocument/documentHighlight' }, sent

    it 'shows the highlights, with writes in their own flair', ->
      document_highlight.request buffer, 16
      callbacks[1] {
        { range: range(0, 0, 0, 6), kind: 3 },
        { range: range(1, 6, 1, 12), kind: 2 },
        { range: range(2, 0, 2, 6) }
      }
      assert.same {
        { 'occurrence_highlight_write', 1, 4 },
        { 'occurrence_highlight', 15, 18 },
        { 'occurrence_highlight', 20, 23 }
      }, shown!

    it 'shows nothing when the symbol occurs only at the cursor', ->
      document_highlight.request buffer, 16
      callbacks[1] { { range: range(1, 6, 1, 12), kind: 2 } }
      assert.same {}, shown!

      document_highlight.request buffer, 2
      callbacks[2] { { range: range(1, 6, 1, 12), kind: 2 } }
      assert.same { { 'occurrence_highlight', 15, 18 } }, shown!

    it 'shows nothing for errors, empty answers and empty ranges', ->
      for response in *{ { nil, 'timed out' }, { nil }, { {} }, { { { range: range(0, 0, 0, 0) } } } }
        document_highlight.request buffer, 16
        callbacks[#callbacks] table.unpack response, 1, 2
        assert.same {}, shown!

    it 'requests nothing unless the cursor is within a word or just after it', ->
      buffer.text = '  åäö = x\n'
      for pos in *{ 1, 2, 3, 7, 9 }
        document_highlight.request buffer, pos
      assert.spy(client.send_request).was_not_called!

      for pos in *{ 4, 6, 10 }
        document_highlight.request buffer, pos
      assert.spy(client.send_request).was_called(3)

    it 'does not request anything when the server has no documentHighlightProvider', ->
      client.capabilities = {}
      document_highlight.request buffer, 16
      assert.spy(client.send_request).was_not_called!

    it 'does nothing for buffers without a language server', ->
      buffer.data.lsp = nil
      document_highlight.request buffer, 16
      assert.spy(client.send_request).was_not_called!

    it 'drops the answer to a request that has been superseded', ->
      document_highlight.request buffer, 16
      document_highlight.request buffer, 2
      assert.spy(client.cancel).was_called_with client, 1
      callbacks[1] answer
      assert.same {}, shown!
      callbacks[2] answer
      assert.equals 2, #shown!

    it 'drops the answer when the buffer has been detached meanwhile', ->
      document_highlight.request buffer, 16
      state = buffer.data.lsp
      buffer.data.lsp = nil
      callbacks[1] answer
      buffer.data.lsp = state
      assert.same {}, shown!

  describe 'shown highlights', ->
    before_each ->
      document_highlight.request buffer, 16
      callbacks[1] answer

    it 'are kept while the cursor is within one of them, or just after it', ->
      for pos in *{ 2, 4, 16, 18 }
        move_to pos
        assert.equals 2, #shown!

    it 'are cleared when the cursor leaves them', ->
      move_to 5
      assert.same {}, shown!

    it 'are cleared when the cursor is just before one of them', ->
      move_to 15
      assert.same {}, shown!

    it 'are cleared when the buffer changes', ->
      buffer\insert 'x', 24
      assert.same {}, shown!

    it 'are cleared when lsp_occurrences_highlighted is turned off', ->
      buffer.config.lsp_occurrences_highlighted = false
      assert.same {}, shown!

  describe 'a pending request', ->
    before_each -> document_highlight.request buffer, 16

    it 'is cancelled when the cursor moves', ->
      move_to 2
      assert.spy(client.cancel).was_called_with client, 1

    it 'is cancelled when the buffer changes', ->
      buffer\insert 'x', 24
      assert.spy(client.cancel).was_called_with client, 1

  describe 'when the cursor rests', ->
    setup -> set_howl_loop!
    before_each -> buffer.config.lsp_occurrences_highlight_delay = 200

    wait = (seconds, f) -> timer.after_exactly seconds, async f

    it 'requests the highlights only after lsp_occurrences_highlight_delay', (done) ->
      move_to 16
      wait 0.1, ->
        assert.spy(client.send_request).was_not_called!
        wait 0.2, ->
          assert.spy(client.send_request).was_called(1)
          done!

    it 'requests the highlights once, for where it rests', (done) ->
      move_to 5
      move_to 2
      move_to 16
      wait 0.3, ->
        assert.spy(client.send_request).was_called(1)
        assert.spy(client.send_request).was_called_with client, 'textDocument/documentHighlight', {
          textDocument: { uri: 'file:///tmp/x.py' },
          position: { line: 1, character: 8 }
        }, match._
        done!

    it 'requests the highlights after an edit in the current editor', (done) ->
      app_editor = app.editor
      app.editor = editor
      editor.cursor.pos = 2
      buffer\insert 'x', 24
      app.editor = app_editor
      wait 0.3, ->
        assert.spy(client.send_request).was_called(1)
        done!

    it 'requests nothing when lsp_occurrences_highlighted is false', (done) ->
      buffer.config.lsp_occurrences_highlighted = false
      move_to 16
      wait 0.3, ->
        assert.spy(client.send_request).was_not_called!
        done!
