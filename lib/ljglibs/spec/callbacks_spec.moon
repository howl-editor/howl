-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

callbacks = require 'ljglibs.callbacks'
ffi = require 'ffi'

C = ffi.C

dispatch = (handle, arg) ->
  cb = ffi.cast('GVCallback2', callbacks.void2)
  cb callbacks.cast_arg(arg), callbacks.cast_arg(handle.id)

describe 'callbacks', ->

  describe 'register(handler, description, handler, ...)', ->
    it 'allows registering a handler that is dispatched to correctly', ->
      handler = spy.new -> nil
      handle = callbacks.register handler, 'test handler'
      dispatch handle, 123
      assert.spy(handler).was_called!

    it 'keeps the handler, allowing multiple callbacks', ->
      handler = spy.new -> nil
      handle = callbacks.register handler, 'test handler'
      dispatch handle, 123
      dispatch handle, 123
      assert.spy(handler).was_called(2)

    it 'passes along any additional arguments to the handler after the callback parameters', ->
      handler = spy.new -> nil
      handle = callbacks.register handler, 'test handler', 'myarg', nil, 123
      dispatch handle, 999999 -- <- random?
      assert.spy(handler).was_called_with callbacks.cast_arg(999999), 'myarg', nil, 123

    context '(gc lifecycle management)', ->
      it 'anchors a handler, preventing it from being garbage collected', ->
        holder = setmetatable { handler: -> }, __mode: 'v'
        handle = callbacks.register holder.handler, 'test handler'
        collectgarbage!
        assert.is_not_nil holder.handler

  describe 'unregister(handle)', ->
    it 'prevents the handler from receiving any more callbacks', ->
      handler = spy.new -> nil
      handle = callbacks.register handler, 'test handler'
      callbacks.unregister handle
      dispatch handle, 123
      assert.spy(handler).was_not_called!

    it 'releases any references', ->
      ref = {}
      holder = setmetatable {}, __mode: 'v'
      table.insert holder, ref

      handler = -> ref['foo']
      handle = callbacks.register handler, 'test handler'
      callbacks.unregister handle

      ref = nil
      handler = nil
      collectgarbage!
      assert.is_nil holder[1]

  describe 'unref_handle(handle)', ->
    it 'un-anchors a handle, allowing the handler to be garbage collected', ->
      holder = setmetatable { handler: -> }, __mode: 'v'
      handle = callbacks.register holder.handler, 'test handler'
      callbacks.unref_handle handle
      collectgarbage!
      assert.is_nil holder.handler

    it 'still dispatches callbacks as long as the handler is alive', ->
      handler = spy.new ->
      handle = callbacks.register handler, 'test handler'
      callbacks.unref_handle handle
      dispatch handle, 123
      assert.spy(handler).was_called!

    it 'handles incoming callbacks if the handler is garbage collected', ->
      holder = setmetatable { handler: -> }, __mode: 'v'
      handle = callbacks.register holder.handler, 'test handler'
      callbacks.unref_handle handle
      collectgarbage!
      dispatch handle, 123
      dispatch handle, 123

    it 'returns the unrefed callback function', ->
      handler = -> nil
      handle = callbacks.register handler, 'test handler'
      assert.equal handler, callbacks.unref_handle handle

  describe '(dispatching)', ->
    it 'dispatches in the main coroutine if the dispatch_in_coroutine option is false', ->
      handler = ->
        _, is_main = coroutine.running!
        assert.is_true is_main

      callbacks.configure dispatch_in_coroutine: false
      handle = callbacks.register handler, 'test handler'
      dispatch handle, 123

    it 'dispatches in a new coroutine if the dispatch_in_coroutine option is true', ->
      handler = ->
        _, is_main = coroutine.running!
        assert.is_false is_main

      callbacks.configure dispatch_in_coroutine: true
      handle = callbacks.register handler, 'test handler'
      dispatch handle, 123
