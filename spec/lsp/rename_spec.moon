rename = require 'howl.lsp.rename'
uri = require 'howl.lsp.uri'
{:app} = howl
{:File} = howl.io

range = (line, s_char, e_line, e_char) -> {
  start: { :line, character: s_char },
  ['end']: { line: e_line, character: e_char }
}

edit = (text, ...) -> { range: range(...), newText: text }

describe 'lsp.rename', ->
  local dir, file, other, buffer, client, responses

  before_each ->
    dir = File.tmpdir!
    file = dir\join 'x.py'
    other = dir\join 'y.py'
    file.contents = 'def foo():\n    pass\nfoo()\n'
    other.contents = 'import x\nx.foo()\n'
    responses = {}
    client = {
      initialized: true,
      capabilities: { renameProvider: { prepareProvider: true }, referencesProvider: true },
      request: spy.new (_, method) -> table.unpack(responses[method] or {}),
      notify: spy.new ->
    }
    buffer = app\new_buffer!
    buffer.file = file
    buffer.data.lsp = { :client, uri: uri.for_file(file), version: 1, dirty: false, changes: {}, full: false }

  after_each ->
    for b in *[b for b in *app.buffers when b.file and b.file\is_below(dir)]
      app\close_buffer b, true
    dir\delete_all!

  describe 'prepare(buffer, pos)', ->
    it 'returns the placeholder given by the server', ->
      responses['textDocument/prepareRename'] = { { range: range(0, 4, 0, 7), placeholder: 'bar' } }
      assert.equals 'bar', rename.prepare(buffer, 6)
      assert.spy(client.request).was_called_with client, 'textDocument/prepareRename', {
        textDocument: { uri: uri.for_file(file) },
        position: { line: 0, character: 5 }
      }

    it 'returns the text of the range given by the server', ->
      buffer.text = 'def fåå():\n'
      responses['textDocument/prepareRename'] = { range(0, 4, 0, 9) }
      assert.equals 'fåå', rename.prepare(buffer, 6)

    it 'returns nil and a message when the server says the symbol cannot be renamed', ->
      responses['textDocument/prepareRename'] = { nil }
      assert.same { nil, "'foo' can't be renamed" }, { rename.prepare(buffer, 6) }

    it 'returns nil and the error when the request fails', ->
      responses['textDocument/prepareRename'] = { nil, 'builtins cannot be renamed' }
      assert.same { nil, 'builtins cannot be renamed' }, { rename.prepare(buffer, 6) }

    it 'returns the word at pos without asking a server that cannot prepare', ->
      client.capabilities.renameProvider = true
      assert.equals 'foo', rename.prepare(buffer, 6)
      assert.spy(client.request).was_not_called!

    it 'returns the word at pos while the server is not yet initialized', ->
      client.initialized = false
      client.capabilities = {}
      assert.equals 'foo', rename.prepare(buffer, 6)

    it 'returns nil and a message when there is no word at pos', ->
      client.capabilities.renameProvider = true
      name, msg = rename.prepare buffer, buffer.lines[2].start_pos + 1
      assert.is_nil name
      assert.match msg, 'symbol'

    it 'returns nil and a message when the server cannot rename', ->
      client.capabilities = {}
      name, msg = rename.prepare buffer, 6
      assert.is_nil name
      assert.match msg, 'does not support renaming'

  describe 'preview_locations(buffer, pos, name)', ->
    workspace_edit = -> {
      documentChanges: {
        { textDocument: { uri: uri.for_file(other) }, edits: { edit('foo', 1, 2, 1, 5) } }
        { textDocument: { uri: uri.for_file(file) }, edits: { edit('foo', 2, 0, 2, 3), edit('foo', 0, 4, 0, 7) } }
      }
    }

    it 'asks for a rename to name, without applying it', ->
      responses['textDocument/rename'] = { workspace_edit! }
      rename.preview_locations buffer, 6, 'foo'
      assert.spy(client.request).was_called_with client, 'textDocument/rename', {
        textDocument: { uri: uri.for_file(file) },
        position: { line: 0, character: 5 },
        newName: 'foo'
      }
      assert.equals 'def foo():\n    pass\nfoo()\n', buffer.text
      assert.is_nil ([b for b in *app.buffers when b.file == other])[1]

    it 'returns the places of the edits, sorted, with the text of their lines', ->
      responses['textDocument/rename'] = { workspace_edit! }
      locations = rename.preview_locations buffer, 6, 'foo'
      assert.same { 'x.py', 'x.py', 'y.py' }, [l.file.basename for l in *locations]
      assert.same { 1, 3, 2 }, [l.line_nr for l in *locations]
      assert.same { 'def foo():', 'foo()', 'x.foo()' }, [l[2] for l in *locations]
      assert.same { 5, 8 }, { locations[1].byte_start_column, locations[1].byte_end_column }

    it 'returns the place at pos as the second value', ->
      responses['textDocument/rename'] = { workspace_edit! }
      locations, at_pos = rename.preview_locations buffer, 6, 'foo'
      assert.equals locations[1], at_pos

    it 'reads the places from changes as well', ->
      responses['textDocument/rename'] = { { changes: { [uri.for_file(other)]: { edit('foo', 1, 2, 1, 5) } } } }
      locations = rename.preview_locations buffer, 6, 'foo'
      assert.same { 2 }, [l.line_nr for l in *locations]

    it 'returns the references when the rename gives nothing', ->
      responses['textDocument/references'] = { { { uri: uri.for_file(file), range: range(2, 0, 2, 3) } } }
      locations = rename.preview_locations buffer, 6, 'foo'
      assert.same { 'foo()' }, [l[2] for l in *locations]
      responses['textDocument/rename'] = { nil, 'failed' }
      locations = rename.preview_locations buffer, 6, 'foo'
      assert.same { 'foo()' }, [l[2] for l in *locations]

    it 'returns nil and a message when there are no places', ->
      locations, msg = rename.preview_locations buffer, 6, 'foo'
      assert.is_nil locations
      assert.match msg, 'no places'

  describe 'rename(buffer, pos, new_name)', ->
    it 'applies the edit of a rename to new_name', ->
      responses['textDocument/rename'] = { {
        changes: { [uri.for_file(file)]: { edit('bår', 0, 4, 0, 7), edit('bår', 2, 0, 2, 3) } }
      } }
      result = rename.rename buffer, 6, 'bår'
      assert.equals 'def bår():\n    pass\nbår()\n', buffer.text
      assert.same { buffer }, result.buffers
      assert.spy(client.request).was_called_with client, 'textDocument/rename', {
        textDocument: { uri: uri.for_file(file) },
        position: { line: 0, character: 5 },
        newName: 'bår'
      }

    it 'returns nil and the error when the request fails', ->
      responses['textDocument/rename'] = { nil, 'name is taken' }
      assert.same { nil, 'name is taken' }, { rename.rename(buffer, 6, 'bar') }

    it 'returns nil and a message when the server gives no edit', ->
      result, msg = rename.rename buffer, 6, 'bar'
      assert.is_nil result
      assert.match msg, 'nothing to rename'
