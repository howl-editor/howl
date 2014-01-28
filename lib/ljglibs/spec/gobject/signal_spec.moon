-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

require 'ljglibs.cdefs.gtk'
gobject = require 'ljglibs.gobject'
ffi = require 'ffi'
import signal from gobject

C = ffi.C

describe 'signal', ->
  local widget

  before_each -> widget = ffi.cast 'GtkWidget *', C.gtk_event_box_new!

  describe 'connect(cb_type, instance, signal, handler, ...)', ->
    it 'allows connecting a handler with a given type', ->
      handler = spy.new ->
      signal.connect('void2', widget, 'show', handler)
      C.gtk_widget_show widget
      assert.spy(handler).was_called_with widget

    it 'passes along any additional arguments to the handler after the callback parameters', ->
      handler = spy.new ->
      signal.connect('void2', widget, 'show', handler, 'myarg', nil, 123)
      C.gtk_widget_show widget
      assert.spy(handler).was_called_with widget, 'myarg', nil, 123

    context '(gc lifecycle management)', ->
      it 'anchors a handler, preventing it from being garbage collected', ->
        holder = setmetatable { handler: -> }, __mode: 'v'
        handle = signal.connect('void2', widget, 'show', holder.handler, 'myarg', nil, 123)
        collectgarbage!
        assert.is_not_nil holder.handler

  describe 'disconnect(handle)', ->
    local handler, handle
    before_each ->
      handler = spy.new ->
      handle = signal.connect('void2', widget, 'show', handler, 'myarg', nil, 123)

    it 'prevents the handler from receiving any more callbacks', ->
      signal.disconnect handle
      C.gtk_widget_show widget
      assert.spy(handler).was_not_called!

  describe 'unref_handle(handle)', ->
    it 'un-anchors a handle, allowing the handler to be garbage collected', ->
      holder = setmetatable { handler: -> }, __mode: 'v'
      handle = signal.connect('void2', widget, 'show', holder.handler, 'myarg', nil, 123)
      signal.unref_handle handle
      collectgarbage!
      assert.is_nil holder.handler

    it 'still dispatches callbacks as long as the handler is alive', ->
      handler = spy.new ->
      handle = signal.connect('void2', widget, 'show', handler, 'myarg', nil, 123)
      signal.unref_handle handle
      C.gtk_widget_show widget
      assert.spy(handler).was_called!

    it 'handles incoming callbacks if the handler is garbage collected', ->
      holder = setmetatable { handler: -> }, __mode: 'v'
      handle = signal.connect('void2', widget, 'show', holder.handler, 'myarg', nil, 123)
      signal.unref_handle handle
      collectgarbage!
      C.gtk_widget_show widget
      C.gtk_widget_hide widget
      C.gtk_widget_show widget

  describe 'emit_by_name(instance, signal, ...)', ->
    it 'allows emitting custom signals', ->
      called_with = nil
      handler = (...) -> called_with = {...}
      handle = signal.connect('void3', widget, 'event-after', handler)
      signal.emit_by_name widget, 'event-after', 'event', handle.id
      assert.equal 2, #called_with
      assert.same { widget, 'event' }, { called_with[1], ffi.string(called_with[2]) }

