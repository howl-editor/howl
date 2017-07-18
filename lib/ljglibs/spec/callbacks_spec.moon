-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

callbacks = require 'ljglibs.callbacks'
ffi = require 'ffi'

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
        callbacks.register holder.handler, 'test handler'
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

      handler_holder = handler: -> ref['foo']
      handle = callbacks.register handler_holder.handler, 'test handler'
      callbacks.unregister handle

      ref = nil
      handler_holder.handler = nil
      collectgarbage!
      assert.is_nil holder[1]

    it 'returns true if there was a handler to unregister', ->
      handler = spy.new -> nil
      handle = callbacks.register handler, 'test handler'
      assert.is_true callbacks.unregister handle
      assert.is_false callbacks.unregister handle


  describe 'unref_handle(handle)', ->
    collect = ->
      -- twice to allow for multiple levels of weak refs to be collected
      collect_memory!

    it 'un-anchors a handle, allowing the handler to be garbage collected', ->
      holder = setmetatable { handler: -> }, __mode: 'v'
      handle = callbacks.register holder.handler, 'test handler'
      callbacks.unref_handle handle
      collect!
      assert.is_nil holder.handler

    it 'ties the life any additional arguments to the handler', ->
      holder = { handler: -> }
      args_holder = setmetatable { {} }, __mode: 'v'
      handle = callbacks.register holder.handler, 'test handler', args_holder[1]
      callbacks.unref_handle handle
      collect!
      assert.is_not_nil holder.handler
      assert.is_not_nil args_holder[1]

      setmetatable holder, __mode: 'v'

      collect!

      assert.is_nil holder.handler
      assert.is_nil args_holder[1]

    it 'still dispatches callbacks correctly as long as the handler is alive', ->
      handler = spy.new ->
      handle = callbacks.register handler, 'test handler', 'myarg'
      callbacks.unref_handle handle
      dispatch handle, 123
      assert.spy(handler).was_called_with callbacks.cast_arg(123), 'myarg'

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
    after_each ->
      callbacks.configure {}

    it 'dispatches directly in the main coroutine if no dispatcher is set', ->
      handler = spy.new ->
        _, is_main = coroutine.running!
        assert.is_true is_main

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
