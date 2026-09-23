Client = require 'howl.lsp.client'
json_rpc = require 'howl.json_rpc'
{:dispatch} = howl
{:File} = howl.io

class FakeProcess
  new: =>
    @written = {}
    @signals = {}
    @exited = false
    @stdin = write: (_, data) -> table.insert @written, data

  pump: (@on_stdout, @on_stderr) =>
    @_exit = dispatch.park 'fake-process-exit'
    dispatch.wait @_exit

  send_signal: (signal) =>
    table.insert @signals, signal

  exit: =>
    @exited = true
    @exit_status_string = 'exited normally with code 0'
    dispatch.resume @_exit

  emit: (msg) =>
    @.on_stdout json_rpc.encode(msg)

  messages: =>
    decoder = json_rpc.Decoder!
    decoder\feed table.concat(@written)

  last_message: =>
    msgs = @messages!
    msgs[#msgs]

describe 'lsp.Client', ->
  local process, client

  before_each ->
    process = FakeProcess!
    client = Client cmd: 'fake-server', root: File('/tmp/proj'), :process

  initialize = (capabilities = { positionEncoding: 'utf-8' }) ->
    client\start!
    init = process\messages![1]
    process\emit { jsonrpc: '2.0', id: init.id, result: { :capabilities } }

  describe 'start()', ->
    it 'sends an initialize request with the root and utf-8 as position encoding', ->
      client\start!
      msg = process\messages![1]
      assert.equals 'initialize', msg.method
      assert.equals 'file:///tmp/proj', msg.params.rootUri
      assert.same { 'utf-8' }, msg.params.capabilities.general.positionEncodings

    it 'sends initialized and stores the server capabilities once the server responds', ->
      initialize { positionEncoding: 'utf-8', completionProvider: {} }
      assert.is_true client.initialized
      assert.same {}, client.capabilities.completionProvider
      assert.equals 'initialized', process\last_message!.method

    it 'holds back other messages until initialization is complete', ->
      client\start!
      client\notify 'textDocument/didOpen', {}
      assert.equals 1, #process\messages!
      init = process\messages![1]
      process\emit { jsonrpc: '2.0', id: init.id, result: { capabilities: { positionEncoding: 'utf-8' } } }
      methods = [m.method for m in *process\messages!]
      assert.same { 'initialize', 'initialized', 'textDocument/didOpen' }, methods

    it 'shuts down the server if it does not support the utf-8 position encoding', ->
      initialize {}
      assert.is_false client.initialized
      assert.is_true client.dead
      assert.same { 'TERM' }, process.signals

  describe 'send_request(method, params, callback)', ->
    before_each -> initialize!

    it 'invokes callback with the result of the matching response', ->
      callback = spy.new ->
      id = client\send_request 'foo', { x: 1 }, callback
      msg = process\last_message!
      assert.same { jsonrpc: '2.0', id: id, method: 'foo', params: { x: 1 } }, msg
      process\emit { jsonrpc: '2.0', id: id + 100, result: 'other' }
      assert.spy(callback).was_not_called!
      process\emit { jsonrpc: '2.0', id: id, result: 'ok' }
      assert.spy(callback).was_called_with 'ok'

    it 'invokes callback with nil and the message for error responses', ->
      callback = spy.new ->
      id = client\send_request 'foo', {}, callback
      process\emit { jsonrpc: '2.0', id: id, error: { code: 1, message: 'bad' } }
      assert.spy(callback).was_called_with nil, 'bad'

    it 'invokes callback with an error when the request times out', ->
      callback = spy.new ->
      client\send_request 'foo', {}, callback, 0
      howl.app\pump_mainloop!
      assert.spy(callback).was_called_with nil, "request 'foo' timed out"

    it 'fails pending requests when the server exits', ->
      callback = spy.new ->
      client\send_request 'foo', {}, callback
      process\exit!
      assert.spy(callback).was_called_with nil, 'server is not running'
      assert.is_true client.dead

    it 'returns nil and an error when the server is not running', ->
      process\exit!
      assert.same { nil, 'server is not running' }, { client\send_request 'foo', {}, -> }

  describe 'request(method, params)', ->
    it 'waits for and returns the result', ->
      initialize!
      local result
      dispatch.launch -> result = client\request 'foo', {}
      process\emit { jsonrpc: '2.0', id: process\last_message!.id, result: 'ok' }
      assert.equals 'ok', result

  describe 'cancel(id)', ->
    it 'sends $/cancelRequest and ignores any later response', ->
      initialize!
      callback = spy.new ->
      id = client\send_request 'foo', {}, callback
      client\cancel id
      assert.same { method: '$/cancelRequest', params: { :id }, jsonrpc: '2.0' }, process\last_message!
      process\emit { jsonrpc: '2.0', :id, result: 'late' }
      assert.spy(callback).was_not_called!

  describe 'server messages', ->
    before_each -> initialize!

    it 'invokes the registered notification handler with the params', ->
      handler = spy.new ->
      client.notification_handlers['window/logMessage'] = handler
      process\emit { jsonrpc: '2.0', method: 'window/logMessage', params: { message: 'hi' } }
      assert.spy(handler).was_called_with { message: 'hi' }

    it 'responds to workspace/configuration requests with nulls', ->
      process\emit { jsonrpc: '2.0', id: 'x', method: 'workspace/configuration', params: { items: { {}, {} } } }
      assert.includes process.written[#process.written], '"result":[null,null]'

    it 'responds with an error to unknown requests', ->
      process\emit { jsonrpc: '2.0', id: 7, method: 'foo/bar' }
      msg = process\last_message!
      assert.equals 7, msg.id
      assert.equals -32601, msg.error.code
