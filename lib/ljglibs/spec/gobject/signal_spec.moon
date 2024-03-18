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

    it 'casts arguments of known types', ->
      box = Gtk.Box.new!
      called_instance = nil
      handler = spy.new (signal_box) -> called_instance = signal_box
      signal.connect(box, 'hide', handler)
      ffi.cast('GtkWidget *', box)\hide!
      assert.spy(handler).was_called(1)
      assert.equal Gtk.Box.append, called_instance.append

    context '(gc lifecycle management)', ->
      it 'anchors a handler, preventing it from being garbage collected', ->
        holder = setmetatable { handler: -> }, __mode: 'v'
        signal.connect(widget, 'hide', holder.handler, 'myarg', nil, 123)
        collectgarbage!
        assert.is_not_nil holder.handler

  describe 'connect_for(lua_ref, cb_type, instance, signal, handler, ...)', ->
    it 'allows connecting a handler with a given type', ->
      lua_ref = {}
      handler = spy.new ->
      signal.connect_for(lua_ref, widget, 'hide', handler)
      C.gtk_widget_hide widget
      assert.spy(handler).was_called_with lua_ref, widget

    it 'passes along any additional arguments to the handler after the callback parameters', ->
      handler = spy.new ->
      lua_ref = {}
      signal.connect_for(lua_ref, widget, 'hide', handler, 'myarg', nil, 123)
      C.gtk_widget_hide widget
      assert.spy(handler).was_called_with lua_ref, widget, 'myarg', nil, 123

    it 'casts arguments of known types', ->
      box = Gtk.Box.new!
      lua_ref = {}
      called_instance = nil
      handler = spy.new (_lua_ref, signal_box) -> called_instance = signal_box
      signal.connect_for(lua_ref, box, 'hide', handler)
      ffi.cast('GtkWidget *', box)\hide!
      assert.spy(handler).was_called(1)
      assert.equal Gtk.Box.append, called_instance.append

    context '(gc lifecycle management)', ->
      it 'anchors the handler, preventing it from being garbage collected', ->
        lua_ref = {}
        holder = setmetatable { handler: -> }, __mode: 'v'
        signal.connect_for(lua_ref, widget, 'hide', holder.handler)
        collectgarbage!
        assert.is_not_nil holder.handler

      it 'does not anchor the lua_ref, allowing it to be garbage collected', ->
        handler = ->
        holder = setmetatable { {} }, __mode: 'v'
        signal.connect_for(holder[1], widget, 'hide', handler)
        collectgarbage!
        assert.is_nil holder[1]

  describe 'disconnect(handle)', ->
    local handler, handle
    before_each ->
      handler = spy.new ->
      handle = signal.connect(widget, 'hide', handler, 'myarg', nil, 123)

    it 'prevents the handler from receiving any more callbacks', ->
      signal.disconnect handle
      C.gtk_widget_hide widget
      assert.spy(handler).was_not_called!

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
