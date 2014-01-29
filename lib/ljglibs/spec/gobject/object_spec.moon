gobject = require 'ljglibs.gobject'
require 'ljglibs.cdefs.gtk'
ffi = require 'ffi'
import Object, Type from gobject

describe 'Object', ->
  setup -> ffi.C.gtk_event_box_new!

  context '(constructing)', ->
    it 'can be created using an existing gtype', ->
      type = Type.from_name 'GtkEventBox'
      o = Object type
      assert.is_not_nil o

    it 'raises an error if type is nil', ->
      type = Type.from_name 'GtkButton2'
      assert.raises 'undefined', -> Object type
