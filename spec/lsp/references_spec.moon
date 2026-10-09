references = require 'howl.lsp.references'
uri = require 'howl.lsp.uri'
{:app, :Buffer} = howl
{:File} = howl.io

range = (line, s_char, e_line, e_char) -> {
  start: { :line, character: s_char },
  ['end']: { line: e_line, character: e_char }
}

ref = (file, ...) -> { uri: uri.for_file(file), range: range(...) }

describe 'lsp.references', ->
  describe 'locations_for(buffer, pos)', ->
    local dir, file, buffer, open_buffer, client, response, err

    before_each ->
      dir = File.tmpdir!
      file = dir\join 'x.py'
      file.contents = 'def foo():\n    pass\nfoo()\n'
      response = { ref(file, 0, 4, 0, 7), ref(file, 2, 0, 2, 3) }
      err = nil
      client = {
        initialized: true,
        capabilities: { referencesProvider: true },
        request: spy.new -> response, err
      }
      buffer = Buffer {}
      buffer.file = file
      buffer.data.lsp = { :client, uri: uri.for_file(file), version: 1, dirty: false, changes: {}, full: false }

    after_each ->
      app\close_buffer open_buffer, true if open_buffer
      open_buffer = nil
      dir\delete_all!

    it 'requests the references for the uri and position, including the declaration', ->
      references.locations_for buffer, 6
      assert.spy(client.request).was_called_with client, 'textDocument/references', {
        textDocument: { uri: uri.for_file(file) },
        position: { line: 0, character: 5 },
        context: { includeDeclaration: true }
      }

    it 'returns the locations with the text of their lines', ->
      locs = references.locations_for buffer, 6
      assert.same { 1, 3 }, [l.line_nr for l in *locs]
      assert.same { 'def foo():', 'foo()' }, [l[2] for l in *locs]

    it 'takes the text of lines from the buffer when the file is open', ->
      open_buffer = app\new_buffer!
      open_buffer.file = file
      open_buffer.text = 'def foo(): # unsaved\n    pass\nfoo()\n'
      locs = references.locations_for buffer, 6
      assert.equals 'def foo(): # unsaved', locs[1][2]

    it 'gives empty text for lines that are not in the file', ->
      response = { ref(file, 9, 0, 9, 3) }
      locs = references.locations_for buffer, 6
      assert.equals '', locs[1][2]

    it 'highlights the reference in the text of its line', ->
      locs = references.locations_for buffer, 6
      assert.same { nil, { { byte_start_column: 5, byte_end_column: 8 } } }, locs[1].item_highlights

    it 'does not highlight references spanning lines', ->
      response = { ref(file, 0, 4, 1, 0) }
      locs = references.locations_for buffer, 6
      assert.is_nil locs[1].item_highlights

    it 'returns the reference at pos as the second value', ->
      locs, at_pos = references.locations_for buffer, buffer.lines[3].start_pos + 1
      assert.equals locs[2], at_pos

    it 'returns no reference at pos when pos is not at one', ->
      _, at_pos = references.locations_for buffer, buffer.lines[2].start_pos
      assert.is_nil at_pos

    it 'returns nil when the server found no references', ->
      response = nil
      assert.is_nil references.locations_for buffer, 6
      response = {}
      assert.is_nil references.locations_for buffer, 6

    it 'returns nil when the request fails', ->
      response, err = nil, 'timed out'
      assert.is_nil references.locations_for buffer, 6

    it 'does not request anything when the server has no referencesProvider', ->
      client.capabilities = {}
      assert.is_nil references.locations_for buffer, 6
      assert.spy(client.request).was_not_called!

    it 'returns nil for buffers without a language server', ->
      buffer.data.lsp = nil
      assert.is_nil references.locations_for buffer, 6
