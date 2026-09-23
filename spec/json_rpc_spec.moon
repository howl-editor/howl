json_rpc = require 'howl.json_rpc'
json = require 'lunajson'

frame = (payload) -> "Content-Length: #{#payload}\r\n\r\n#{payload}"

describe 'JSON RPC', ->
  describe 'request(method, params [, id])', ->
    it 'constructs valid JSON RPC', ->
      assert.same {
        jsonrpc: "2.0", method: "foo", params: {'bar', 123}, id: 111
      }, json_rpc.request('foo', {'bar', 123}, 111)

  describe 'encode(message)', ->
    it 'prefixes the JSON payload with a Content-Length header in bytes', ->
      msg = json_rpc.notification 'åäö', {}
      encoded = json_rpc.encode msg
      payload = encoded\match '\r\n\r\n(.*)$'
      assert.equals frame(payload), encoded
      assert.same msg, json.decode(payload)

    it 'encodes json_rpc.null as null and empty_array() as an array', ->
      encoded = json_rpc.encode { a: json_rpc.null, b: json_rpc.empty_array!, c: {} }
      payload = encoded\match '\r\n\r\n(.*)$'
      assert.includes payload, '"a":null'
      assert.includes payload, '"b":[]'
      assert.includes payload, '"c":{}'

  describe 'Decoder', ->
    local decoder
    before_each -> decoder = json_rpc.Decoder!

    it 'returns decoded messages for complete input', ->
      msg = {jsonrpc: "2.0", result: 19, id: 1}
      assert.same { msg }, decoder\feed frame(json.encode msg)

    it 'handles messages split across several chunks', ->
      data = frame json.encode({id: 1, result: 'ÅÄÖ'})
      assert.same {}, decoder\feed data\sub(1, 10)
      assert.same {}, decoder\feed data\sub(11, #data - 3)
      assert.same { {id: 1, result: 'ÅÄÖ'} }, decoder\feed data\sub(#data - 2)

    it 'handles several messages in one chunk', ->
      data = frame(json.encode {id: 1}) .. frame(json.encode {id: 2}) .. 'Content-'
      assert.same { {id: 1}, {id: 2} }, decoder\feed data
      assert.same { {id: 3} }, decoder\feed frame(json.encode {id: 3})\sub(9)

    it 'ignores additional headers', ->
      payload = json.encode {id: 1}
      data = "Content-Type: application/vscode-jsonrpc; charset=utf-8\r\ncontent-length: #{#payload}\r\n\r\n#{payload}"
      assert.same { {id: 1} }, decoder\feed data
