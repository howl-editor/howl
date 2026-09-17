-- Copyright 2014-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

callbacks = require 'ljglibs.callbacks'
ffi = require 'ffi'

dispatch = (handle, arg) ->
  cb = ffi.cast('GVCallback2', callbacks.void2)
  cb callbacks.cast_arg(arg), callbacks.cast_arg(handle.id)

describe 'callbacks', ->

  describe "register(handler, description, handler, ...)", ->
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
        callbacks.register holder.handler, 'test handler'
        collectgarbage!
        assert.is_not_nil holder.handler

      it 'anchors arguments, preventing them from being garbage collected', ->
        arg = {}
        handler = ->
        holder = setmetatable { arg }, __mode: 'v'
        callbacks.register handler, 'test handler', arg
        arg = nil
        collectgarbage!
        assert.is_not_nil holder[1]

  describe 'register_for_instance(instance, handler, description, handler, ...)', ->
    it 'dispatches callbacks with instance as the first argument', ->
      instance = {}
      handler = spy.new ->
      handle = callbacks.register_for_instance instance, handler, 'for_instance', 'my_arg'
      dispatch handle, 123
      assert.spy(handler).was_called_with instance, callbacks.cast_arg(123), 'my_arg'

    context '(gc lifecycle management)', ->
      it 'does not anchor the instance, allowing it to be garbage collected', ->
        handler = ->
        holder = setmetatable { instance: {} }, __mode: 'v'
        callbacks.register_for_instance holder.instance, handler, 'no anchor instance'
        count = callbacks.count!
        collectgarbage!
        collectgarbage!
        assert.is_nil holder.handler
        assert.equal count - 1, callbacks.count!

      it 'removes the callback if the instance is gone', ->
        handler = ->
        holder = setmetatable { instance: {} }, __mode: 'v'
        handle = callbacks.register_for_instance holder.instance, handler, 'gone callback'
        collectgarbage!
        dispatch handle, 123
        assert.is_nil holder.handler
        assert.is_false callbacks.unregister handle

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

      handler_holder = handler: -> ref['foo']
      handle = callbacks.register handler_holder.handler, 'test handler'
      callbacks.unregister handle

      ref = nil
      handler_holder.handler = nil
      collectgarbage!
      assert.is_nil holder[1]

    it 'returns true if there was a handler to unregister and false otherwise', ->
      handler = spy.new -> nil
      handle = callbacks.register handler, 'test handler'
      assert.is_true callbacks.unregister handle
      assert.is_false callbacks.unregister handle

  describe '(dispatching)', ->
    after_each ->
      callbacks.configure {}

    it 'dispatches directly if no dispatcher is set', ->
      handler = spy.new ->
      handle = callbacks.register handler, 'test handler'
      dispatch handle, 123
      assert.spy(handler).was_called(1)

    it 'uses the provided dispatcher if set', ->
      handler = spy.new ->
      dispatcher = spy.new (f) ->
        assert.spy(handler).was_not_called!
        f!
        assert.spy(handler).was_called(1)

      callbacks.configure :dispatcher
      handle = callbacks.register handler, 'test handler'
      dispatch handle, 123
      assert.spy(dispatcher).was_called(1)

  describe 'callback creation', ->
    it 'automatically creates callbacks as needed', ->
      assert.is_not_nil callbacks['void(gpointer)']
