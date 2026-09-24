hover = require 'howl.lsp.hover'
{:Buffer} = howl

describe 'lsp.hover', ->
  describe 'to_markdown(contents)', ->
    it 'returns markdown MarkupContent as is', ->
      assert.equals '**x**', hover.to_markdown kind: 'markdown', value: '**x**'

    it 'fences plaintext MarkupContent', ->
      assert.equals '```\nx: int\n```', hover.to_markdown kind: 'plaintext', value: 'x: int'

    it 'returns a MarkedString string as is', ->
      assert.equals '*x*', hover.to_markdown '*x*'

    it 'fences a MarkedString with a language', ->
      assert.equals '```python\ndef f()\n```', hover.to_markdown language: 'python', value: 'def f()'

    it 'joins a list of MarkedStrings with blank lines', ->
      text = hover.to_markdown { { language: 'lua', value: 'x' }, '', 'doc' }
      assert.equals '```lua\nx\n```\n\ndoc', text

    it 'returns nil for missing or blank contents', ->
      assert.is_nil hover.to_markdown nil
      assert.is_nil hover.to_markdown kind: 'markdown', value: '  '
      assert.is_nil hover.to_markdown {}

  describe 'doc_for(buffer, pos)', ->
    local buffer, client, response

    before_each ->
      response = contents: { kind: 'markdown', value: 'The **doc**' }
      client = {
        initialized: true,
        capabilities: { hoverProvider: true },
        request: spy.new -> response
      }
      buffer = Buffer {}
      buffer.text = 'åäö\nfoo'
      buffer.data.lsp = { :client, uri: 'file:///tmp/x.py', version: 1, dirty: false, changes: {}, full: false }

    it 'requests the hover for the uri and position', ->
      hover.doc_for buffer, 6
      assert.spy(client.request).was_called_with client, 'textDocument/hover', {
        textDocument: { uri: 'file:///tmp/x.py' },
        position: { line: 1, character: 1 }
      }

    it 'returns a buffer with the rendered documentation', ->
      doc = hover.doc_for buffer, 6
      assert.equals 'The doc', doc.text
      assert.equals 'emphasis', howl.ui.style.at_pos(doc, 5)

    it 'returns nil when there is no documentation', ->
      response = nil
      assert.is_nil hover.doc_for buffer, 6
      response = contents: { kind: 'markdown', value: '' }
      assert.is_nil hover.doc_for buffer, 6

    it 'does not request anything when the server has no hoverProvider', ->
      client.capabilities = {}
      assert.is_nil hover.doc_for buffer, 6
      assert.spy(client.request).was_not_called!

    it 'returns nil for buffers without a language server', ->
      buffer.data.lsp = nil
      assert.is_nil hover.doc_for buffer, 6
