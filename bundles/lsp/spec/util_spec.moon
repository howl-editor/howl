{:bundle} = howl
json = require 'lunajson'

describe 'bundle.lsp.util', ->
  local util
  setup ->
    bundle.load_by_name 'lsp'
    util = _G.bundles.lsp.util

  teardown -> bundle.unload 'lsp'

  describe 'decode_one(s)', ->
    it 'returns a decoded object for a valid string', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      payload = json.encode(msg)
      dec = util.decode_one("Content-Length:#{#payload}\r\n\r\n#{payload}")
      assert.same msg, dec

    it 'returns [nil, s] for an incomplete message', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      payload = json.encode(msg)
      sent = "Content-Length:#{#payload}\r\n\r\n#{payload\sub(1, -2)}"
      dec,rest = util.decode_one(sent)
      assert.is_nil dec
      assert.equals sent, rest

    it 'returns [msg, rest] for one and a half', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      msg2 = {jsonrpc: "2.0", result: 123, id: 2}
      p1 = json.encode(msg)
      p2 = json.encode(msg2)
      rest_part = "Content-Length:#{#p2}\r\n\r\n#{p2\sub(1, -2)}"
      dec, rest = util.decode_one("Content-Length:#{#p1}\r\n\r\n#{p1}#{rest_part}")
      assert.same msg, dec
      assert.equals rest_part, rest

  describe 'decode(s)', ->
    it 'returns a decoded object for a valid string', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      payload = json.encode(msg)
      dec = util.decode("Content-Length:#{#payload}\r\n\r\n#{payload}")
      assert.same {msg}, dec

    it 'returns [{}, s] for an incomplete message', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      payload = json.encode(msg)
      sent = "Content-Length:#{#payload}\r\n\r\n#{payload\sub(1, -2)}"
      messages,rest = util.decode(sent)
      assert.same, {}, messages
      assert.equals sent, rest

    it 'returns [{msg}, rest] for one and a half', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      msg2 = {jsonrpc: "2.0", result: 123, id: 2}
      p1 = json.encode(msg)
      p2 = json.encode(msg2)
      rest_part = "Content-Length:#{#p2}\r\n\r\n#{p2\sub(1, -2)}"
      messages, rest = util.decode("Content-Length:#{#p1}\r\n\r\n#{p1}#{rest_part}")
      assert.same {msg}, messages
      assert.equals rest_part, rest

    it 'returns two messages when available', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      msg2 = {jsonrpc: "2.0", result: 123, id: 2}
      p1 = json.encode(msg)
      p2 = json.encode(msg2)
      s = table.concat {
        "Content-Length:#{#p1}\r\n\r\n#{p1}"
        "Content-Length:#{#p2}\r\n\r\n#{p2}"
      }
      messages, rest = util.decode(s)
      assert.same {msg, msg2}, messages
      assert.equals '', rest
