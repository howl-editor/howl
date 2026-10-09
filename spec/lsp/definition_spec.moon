definition = require 'howl.lsp.definition'
{:Buffer} = howl
{:File} = howl.io

range = (line, s_char, e_line, e_char) -> {
  start: { :line, character: s_char },
  ['end']: { line: e_line, character: e_char }
}

describe 'lsp.definition', ->
  describe 'to_locations(result, root)', ->
    it 'converts a Location to a list with a location for its start', ->
      locs = definition.to_locations uri: 'file:///tmp/x.py', range: range(2, 4, 2, 7)
      assert.equals 1, #locs
      with locs[1]
        assert.equals File('/tmp/x.py'), .file
        assert.equals 3, .line_nr
        assert.equals 5, .byte_column
        assert.equals 5, .byte_start_column
        assert.equals 8, .byte_end_column

    it 'converts a list of Locations', ->
      locs = definition.to_locations {
        { uri: 'file:///tmp/a.py', range: range(0, 0, 0, 1) },
        { uri: 'file:///tmp/b.py', range: range(1, 0, 1, 1) }
      }
      assert.same { File('/tmp/a.py'), File('/tmp/b.py') }, [l.file for l in *locs]

    it 'uses the target selection range of a LocationLink', ->
      locs = definition.to_locations {
        {
          targetUri: 'file:///tmp/x.py',
          targetRange: range(1, 0, 3, 0),
          targetSelectionRange: range(1, 4, 1, 7)
        }
      }
      assert.equals 2, locs[1].line_nr
      assert.equals 5, locs[1].byte_column

    it 'ends the highlight at the start for ranges spanning lines', ->
      locs = definition.to_locations uri: 'file:///tmp/x.py', range: range(1, 2, 4, 0)
      assert.equals 3, locs[1].byte_end_column

    it 'drops duplicate locations', ->
      locs = definition.to_locations {
        { uri: 'file:///tmp/x.py', range: range(3, 8, 3, 13) },
        { uri: 'file:///tmp/x.py', range: range(3, 8, 3, 13) },
        { uri: 'file:///tmp/x.py', range: range(3, 9, 3, 13) }
      }
      assert.same { 9, 10 }, [l.byte_column for l in *locs]

    it 'skips locations that are not for files', ->
      locs = definition.to_locations {
        { uri: 'untitled:Untitled-1', range: range(0, 0, 0, 1) },
        { uri: 'file:///tmp/x.py', range: range(0, 0, 0, 1) }
      }
      assert.equals 1, #locs
      assert.equals File('/tmp/x.py'), locs[1].file

    it 'shows paths relative to root when below it', ->
      locs = definition.to_locations {
        { uri: 'file:///tmp/proj/pkg/x.py', range: range(9, 0, 9, 1) },
        { uri: 'file:///usr/lib/y.py', range: range(0, 0, 0, 1) }
      }, File('/tmp/proj')
      assert.equals 'pkg/x.py:10', tostring locs[1][1]
      assert.equals '/usr/lib/y.py:1', tostring locs[2][1]

    it 'returns an empty list for a missing result', ->
      assert.same {}, definition.to_locations nil

  describe 'locations_for(buffer, pos, method)', ->
    local buffer, client, response, err

    before_each ->
      response = { uri: 'file:///tmp/y.py', range: range(0, 4, 0, 7) }
      err = nil
      client = {
        initialized: true,
        capabilities: { definitionProvider: true },
        request: spy.new -> response, err
      }
      buffer = Buffer {}
      buffer.text = 'åäö\nfoo'
      buffer.data.lsp = { :client, uri: 'file:///tmp/x.py', version: 1, dirty: false, changes: {}, full: false }

    it 'requests the definition for the uri and position', ->
      definition.locations_for buffer, 6
      assert.spy(client.request).was_called_with client, 'textDocument/definition', {
        textDocument: { uri: 'file:///tmp/x.py' },
        position: { line: 1, character: 1 }
      }

    it 'returns the definition locations', ->
      locs = definition.locations_for buffer, 6
      assert.equals 1, #locs
      assert.equals File('/tmp/y.py'), locs[1].file
      assert.equals 5, locs[1].byte_column

    it 'returns nil when the server found no definition', ->
      response = nil
      assert.is_nil definition.locations_for buffer, 6
      response = {}
      assert.is_nil definition.locations_for buffer, 6

    it 'returns nil when the request fails', ->
      response, err = nil, 'timed out'
      assert.is_nil definition.locations_for buffer, 6

    it 'does not request anything when the server has no definitionProvider', ->
      client.capabilities = {}
      assert.is_nil definition.locations_for buffer, 6
      assert.spy(client.request).was_not_called!

    it 'requests the given method when the server provides it', ->
      client.capabilities = { typeDefinitionProvider: true }
      locs = definition.locations_for buffer, 6, 'typeDefinition'
      assert.spy(client.request).was_called_with client, 'textDocument/typeDefinition', {
        textDocument: { uri: 'file:///tmp/x.py' },
        position: { line: 1, character: 1 }
      }
      assert.equals File('/tmp/y.py'), locs[1].file

    it 'does not request anything when the server does not provide the given method', ->
      assert.is_nil definition.locations_for buffer, 6, 'implementation'
      assert.spy(client.request).was_not_called!

    it 'returns nil for buffers without a language server', ->
      buffer.data.lsp = nil
      assert.is_nil definition.locations_for buffer, 6
