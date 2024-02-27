-- Copyright 2014-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

require 'ljglibs.cdefs.gtk'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget' -- for instantiating the widget type
ffi = require 'ffi'
import signal, Type from gobject
Gtk = require 'ljglibs.gtk'

C = ffi.C

describe 'signal', ->
  local widget

  before_each ->
    widget = ffi.cast 'GtkWidget *', Gtk.Box.new!

  describe 'connect(cb_type, instance, signal, handler, ...)', ->
    it 'allows connecting a handler with a given type', ->
      handler = spy.new ->
      signal.connect(widget, 'hide', handler)
      C.gtk_widget_hide widget
      assert.spy(handler).was_called_with widget

    it 'passes along any additional arguments to the handler after the callback parameters', ->
      handler = spy.new ->
      signal.connect(widget, 'hide', handler, 'myarg', nil, 123)
      C.gtk_widget_hide widget
      assert.spy(handler).was_called_with widget, 'myarg', nil, 123

    context '(gc lifecycle management)', ->
      it 'anchors a handler, preventing it from being garbage collected', ->
        holder = setmetatable { handler: -> }, __mode: 'v'
        signal.connect(widget, 'hide', holder.handler, 'myarg', nil, 123)
        collectgarbage!
        assert.is_not_nil holder.handler

  describe 'disconnect(handle)', ->
    local handler, handle
    before_each ->
      handler = spy.new ->
      handle = signal.connect(widget, 'hide', handler, 'myarg', nil, 123)

    it 'prevents the handler from receiving any more callbacks', ->
      signal.disconnect handle
      C.gtk_widget_hide widget
      assert.spy(handler).was_not_called!

  describe 'unref_handle(handle)', ->
    it 'un-anchors a handle, allowing the handler to be garbage collected', ->
      holder = setmetatable { handler: -> }, __mode: 'v'
      handle = signal.connect(widget, 'hide', holder.handler, 'myarg', nil, 123)
      signal.unref_handle handle
      collectgarbage!
      assert.is_nil holder.handler

    it 'still dispatches callbacks as long as the handler is alive', ->
      handler = spy.new ->
      handle = signal.connect(widget, 'hide', handler, 'myarg', nil, 123)
      signal.unref_handle handle
      C.gtk_widget_hide widget
      assert.spy(handler).was_called!

    it 'returns the unrefed callback function', ->
      handler = ->
      handle = signal.connect(widget, 'hide', handler)
      assert.equal handler, signal.unref_handle handle

  describe 'lookup(name, gtype)', ->
    it 'returns a signal id for the given name and gtype', ->
      signal_id = signal.lookup 'destroy', Type.from_name 'GtkWidget'
      assert.equal 'number', type signal_id

  describe 'list_ids(gtype)', ->
    it 'returns a list of signal ids for a specific gtype', ->
      gtype = Type.from_name 'GtkWidget'
      ids = signal.list_ids gtype
      assert.not_equal 0, #ids
      for n in *ids
        assert.equal 'number', type(n)

  describe 'query(signal_id)', ->
    it 'returns a GQueryInfo table for the given signal_id', ->
      gtype = Type.from_name 'GtkWidget'
      info = signal.query signal.lookup 'destroy', gtype
      assert.is_not_nil info
      assert.equal Type.from_name('void'), info.return_type
      assert.equal 0, info.n_params
