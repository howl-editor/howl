json_rpc = require 'howl.json_rpc'

describe 'JSON RPC', ->
  describe 'request(method, params [, id])', ->
    it 'constructs valid JSON RPC', ->
      assert.same {
        jsonrpc: "2.0", method: "foo", params: {'bar', 123}, id: 111
      }, json_rpc.request('foo', {'bar', 123}, 111)
