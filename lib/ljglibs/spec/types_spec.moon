ffi = require 'ffi'
types = require 'ljglibs.types'
Type = require 'ljglibs.gobject.type'
Gtk = require 'ljglibs.gtk'
import Box from Gtk

describe 'types', ->
  describe 'cast(gtype, instance)', ->
    it 'supports some basic types', ->
      v = ffi.cast 'void *', 1
      assert.equal 1, types.cast(Type.from_name('guint'), v)

    it 'supports ljglibs definitions', ->
      box = Box!
      v = ffi.cast 'void *', box
      box2 = types.cast(Type.from_name('GtkBox'), v)
      assert.equals Box.new, box2.new

  describe 'cast_widget_ptr(ptr)', ->
    it 'return nil for a NULL pointer', ->
      v = ffi.cast 'void *', nil
      assert.is_nil types.cast_widget_ptr(v)

    it 'returns a casted ptr for a supported widget type', ->
      box = Box!
      v = ffi.cast 'void *', box
      box2 = types.cast_widget_ptr(v)
      assert.equals 'GtkBox', box2.__type
