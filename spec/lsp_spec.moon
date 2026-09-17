lsp = require 'howl.lsp'
json = require 'lunajson'

describe 'LSP', ->
  describe 'decode(s)', ->
    it 'returns a decoded object for a valid string', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      payload = json.encode(msg)
      dec = lsp.decode("Content-Length:#{#payload}\r\n\r\n#{payload}")
      assert.same msg, dec

