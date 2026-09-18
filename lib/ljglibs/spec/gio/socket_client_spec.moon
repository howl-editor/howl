-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

SocketClient = require 'ljglibs.gio.socket_client'
cancellable = require 'ljglibs.gio.cancellable'
dispatch = howl.dispatch

-- connects and returns either the connection or the error text, without ever
-- leaving the local machine
connect = (uri, port, opts = {}) ->
  client = SocketClient!
  client.tls = opts.tls == true
  client.timeout = opts.timeout or 5
  handle = dispatch.park 'spec-socket-connect'

  client\connect_to_uri_async uri, port, opts.cancellable, (ok, ret, code, domain) ->
    if ok
      dispatch.resume handle, true, ret
    else
      dispatch.resume handle, false, ret, code, domain

  -- the client must stay referenced for the whole operation, or ffi.gc unrefs it
  -- under the callback
  ok, ret, code, domain = dispatch.wait handle
  client, ok, ret, code, domain

describe 'gio.SocketClient', ->
  it 'constructs', ->
    assert.is_not_nil SocketClient!

  describe 'properties', ->
    it 'tls defaults to false and round-trips', ->
      client = SocketClient!
      assert.is_false client.tls
      client.tls = true
      assert.is_true client.tls
      client.tls = false
      assert.is_false client.tls

    it 'timeout round-trips', ->
      client = SocketClient!
      client.timeout = 17
      assert.equal 17, client.timeout

    it 'enable_proxy defaults to true and round-trips', ->
      client = SocketClient!
      assert.is_true client.enable_proxy
      client.enable_proxy = false
      assert.is_false client.enable_proxy

  describe 'tls_supported()', ->
    it 'returns a boolean', ->
      assert.includes {true, false}, SocketClient.tls_supported!

  describe 'connect_to_uri_async()', ->
    it 'reports a refused connection rather than raising', (done) ->
      howl_async ->
        -- port 1 on loopback: nothing listens there, and nothing leaves the host
        _, ok, err, code, domain = connect 'http://127.0.0.1:1/', 1
        assert.is_false ok
        assert.is_string err
        assert.is_not_nil code
        assert.is_not_nil domain
        done!

    it 'reports an unresolvable host', (done) ->
      howl_async ->
        _, ok, err = connect 'http://invalid.invalid/', 80
        assert.is_false ok
        assert.is_string err
        done!

    it 'reports cancellation when the cancellable is already cancelled', (done) ->
      howl_async ->
        c = cancellable.create!
        cancellable.cancel c
        assert.is_true cancellable.is_cancelled(c)
        _, ok, err = connect 'http://127.0.0.1:1/', 1, cancellable: c
        assert.is_false ok
        assert.is_string err
        done!

describe 'gio.cancellable', ->
  it 'creates an uncancelled cancellable', ->
    c = cancellable.create!
    assert.is_not_nil c
    assert.is_false cancellable.is_cancelled(c)

  it 'cancels and resets', ->
    c = cancellable.create!
    cancellable.cancel c
    assert.is_true cancellable.is_cancelled(c)
    cancellable.reset c
    assert.is_false cancellable.is_cancelled(c)

  it 'tolerates nil', ->
    assert.has_no_error -> cancellable.cancel nil
    assert.is_false cancellable.is_cancelled(nil)
